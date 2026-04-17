/// One-shot session classification.
///
/// A session is considered "one-shot" when the model completes the task without
/// rework cycles. We detect rework via the pattern:
///   Edit|Write|MultiEdit|NotebookEdit  →  Bash  →  Edit|Write|MultiEdit|NotebookEdit
///
/// Note: Heimdall does not currently capture tool *arguments* (file paths,
/// bash command text). We therefore cannot check whether the *same file* was
/// edited both before and after the Bash call (the ROADMAP's original wording).
/// The adjusted heuristic — any Edit→Bash→Edit sequence, regardless of which
/// file — is a conservative proxy: it will flag more sessions as not-one-shot
/// than the "same-file" variant, but it never misses a genuine rework cycle.
///
/// Named constants for the tool-name sets used by the heuristic:
const EDIT_TOOLS: &[&str] = &["Edit", "Write", "MultiEdit", "NotebookEdit"];
const BASH_TOOLS: &[&str] = &["Bash"];

use crate::models::Turn;

/// Returns whether a tool name is an edit-type tool.
fn is_edit(name: &str) -> bool {
    EDIT_TOOLS.contains(&name)
}

/// Returns whether a tool name is a bash-type tool.
fn is_bash(name: &str) -> bool {
    BASH_TOOLS.contains(&name)
}

/// Classify whether a session is "one-shot".
///
/// - Returns `None` when the session has zero edit turns (no edit activity
///   → not classifiable).
/// - Returns `Some(true)` when edit turns exist but no `Edit→Bash→Edit`
///   pattern appears (task completed without rework cycles).
/// - Returns `Some(false)` when the `Edit→Bash→Edit` pattern appears at
///   least once (rework detected).
///
/// The function is pure: no I/O, no mutable global state.
pub fn classify_one_shot(turns_in_chronological_order: &[Turn]) -> Option<bool> {
    // Collect the tool names in order, filtering to only edit/bash tool turns.
    // Turns without a tool_name are irrelevant to this heuristic.
    let relevant: Vec<&str> = turns_in_chronological_order
        .iter()
        .filter_map(|t| t.tool_name.as_deref())
        .filter(|name| is_edit(name) || is_bash(name))
        .collect();

    // If no edit tools appear at all, the session is not classifiable.
    let has_any_edit = relevant.iter().any(|name| is_edit(name));
    if !has_any_edit {
        return None;
    }

    // Walk the relevant sequence looking for Edit→Bash→Edit.
    // State machine: track whether we have seen an edit that was followed by a bash.
    let mut edit_seen = false;
    let mut edit_then_bash_seen = false;

    for name in &relevant {
        if is_edit(name) {
            if edit_then_bash_seen {
                // Pattern complete: Edit → Bash → Edit
                return Some(false);
            }
            edit_seen = true;
        } else if is_bash(name) && edit_seen {
            edit_then_bash_seen = true;
        }
    }

    Some(true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::Turn;

    /// Build a minimal Turn with only `tool_name` set.
    fn tool_turn(name: &str) -> Turn {
        Turn {
            tool_name: Some(name.to_string()),
            ..Turn::default()
        }
    }

    /// Build a Turn with no tool (e.g., a pure assistant message).
    fn no_tool_turn() -> Turn {
        Turn {
            tool_name: None,
            ..Turn::default()
        }
    }

    // ── None cases (no edit activity) ──────────────────────────────────────

    #[test]
    fn test_classify_no_turns_returns_none() {
        assert_eq!(classify_one_shot(&[]), None);
    }

    #[test]
    fn test_classify_no_edit_tools_returns_none() {
        let turns = vec![no_tool_turn(), tool_turn("Bash"), no_tool_turn()];
        assert_eq!(classify_one_shot(&turns), None);
    }

    #[test]
    fn test_classify_only_bash_returns_none() {
        let turns = vec![tool_turn("Bash"), tool_turn("Bash")];
        assert_eq!(classify_one_shot(&turns), None);
    }

    // ── Some(true) cases (one-shot) ────────────────────────────────────────

    #[test]
    fn test_classify_single_edit_is_one_shot() {
        let turns = vec![tool_turn("Edit")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_write_only_is_one_shot() {
        let turns = vec![tool_turn("Write")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_multiedit_only_is_one_shot() {
        let turns = vec![tool_turn("MultiEdit")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_notebookedit_only_is_one_shot() {
        let turns = vec![tool_turn("NotebookEdit")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_edit_no_bash_is_one_shot() {
        // Edit → Edit → Edit  (no bash in between)
        let turns = vec![tool_turn("Edit"), tool_turn("Edit"), tool_turn("Write")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_bash_then_edit_is_one_shot() {
        // Bash before any edit — pattern requires Edit first, so this is one-shot.
        let turns = vec![tool_turn("Bash"), tool_turn("Edit")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_edit_then_bash_only_is_one_shot() {
        // Edit → Bash but no second edit → not a complete rework cycle.
        let turns = vec![tool_turn("Edit"), tool_turn("Bash")];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_multiple_bash_after_edit_is_one_shot() {
        // Edit → Bash → Bash → Bash (no second Edit)
        let turns = vec![
            tool_turn("Edit"),
            tool_turn("Bash"),
            tool_turn("Bash"),
            tool_turn("Bash"),
        ];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    #[test]
    fn test_classify_interleaved_nontool_turns_one_shot() {
        // Non-tool turns should be ignored; Edit (no-tool) Bash (no-tool) → still one-shot.
        let turns = vec![
            no_tool_turn(),
            tool_turn("Edit"),
            no_tool_turn(),
            tool_turn("Bash"),
            no_tool_turn(),
        ];
        assert_eq!(classify_one_shot(&turns), Some(true));
    }

    // ── Some(false) cases (not one-shot) ──────────────────────────────────

    #[test]
    fn test_classify_edit_bash_edit_is_not_one_shot() {
        // Classic rework cycle: Edit → Bash → Edit
        let turns = vec![tool_turn("Edit"), tool_turn("Bash"), tool_turn("Edit")];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }

    #[test]
    fn test_classify_write_bash_write_is_not_one_shot() {
        let turns = vec![tool_turn("Write"), tool_turn("Bash"), tool_turn("Write")];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }

    #[test]
    fn test_classify_edit_bash_bash_edit_is_not_one_shot() {
        // Multiple bash calls between edits still counts as the pattern.
        let turns = vec![
            tool_turn("Edit"),
            tool_turn("Bash"),
            tool_turn("Bash"),
            tool_turn("Edit"),
        ];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }

    #[test]
    fn test_classify_edit_bash_write_is_not_one_shot() {
        // Mix of edit tool types.
        let turns = vec![tool_turn("Edit"), tool_turn("Bash"), tool_turn("Write")];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }

    #[test]
    fn test_classify_write_bash_multiedit_is_not_one_shot() {
        let turns = vec![
            tool_turn("Write"),
            tool_turn("Bash"),
            tool_turn("MultiEdit"),
        ];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }

    #[test]
    fn test_classify_interleaved_pattern_not_one_shot() {
        // Non-tool turns in between should not break the pattern.
        let turns = vec![
            no_tool_turn(),
            tool_turn("Edit"),
            no_tool_turn(),
            tool_turn("Bash"),
            no_tool_turn(),
            tool_turn("Edit"),
            no_tool_turn(),
        ];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }

    #[test]
    fn test_classify_pattern_appears_once_in_long_sequence() {
        // One rework cycle buried in otherwise-clean sequence.
        let turns = vec![
            tool_turn("Edit"),
            tool_turn("Edit"),
            tool_turn("Bash"),
            tool_turn("Edit"), // ← this triggers the pattern
            tool_turn("Edit"),
        ];
        assert_eq!(classify_one_shot(&turns), Some(false));
    }
}
