/// Hardcoded allowlists for coding-agent components.
///
/// Claude components are matched by their stable Statuspage IDs.
/// OpenAI components are matched by name substring (case-insensitive) because
/// the incident.io shim does not expose a stable `group_id`.
/// Claude component IDs of interest (hardcoded; stable per the plan research).
pub const CLAUDE_COMPONENT_IDS: &[&str] = &[
    "yyzkbfz2thpt", // Claude Code
    "k8w3r06qmzrp", // Claude API (api.anthropic.com)
];

/// OpenAI component names of interest (match by case-insensitive substring).
pub const OPENAI_COMPONENT_NAMES: &[&str] = &[
    "Codex API",
    "Codex Web",
    "CLI",
    "VS Code extension",
    "Responses",
    "Agent",
];

/// Returns true if the given component ID is in the Claude allowlist.
pub fn claude_component_allowed(id: &str) -> bool {
    CLAUDE_COMPONENT_IDS.contains(&id)
}

/// Returns true if the given component name matches any OpenAI allowlist entry
/// (case-insensitive exact or substring match).
pub fn openai_component_allowed(name: &str) -> bool {
    let lower = name.to_lowercase();
    OPENAI_COMPONENT_NAMES
        .iter()
        .any(|allowed| lower.contains(&allowed.to_lowercase()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_claude_allowlist() {
        assert!(claude_component_allowed("yyzkbfz2thpt"));
        assert!(claude_component_allowed("k8w3r06qmzrp"));
        assert!(!claude_component_allowed("unknown-id-xyz"));
        assert!(!claude_component_allowed(""));
    }

    #[test]
    fn test_openai_allowlist_exact() {
        assert!(openai_component_allowed("Codex API"));
        assert!(openai_component_allowed("Codex Web"));
        assert!(openai_component_allowed("CLI"));
        assert!(openai_component_allowed("VS Code extension"));
        assert!(openai_component_allowed("Responses"));
        assert!(openai_component_allowed("Agent"));
    }

    #[test]
    fn test_openai_allowlist_case_insensitive() {
        assert!(openai_component_allowed("codex api"));
        assert!(openai_component_allowed("CODEX WEB"));
        assert!(openai_component_allowed("vs code extension"));
    }

    #[test]
    fn test_openai_allowlist_rejects_unknown() {
        assert!(!openai_component_allowed("Streaming API"));
        assert!(!openai_component_allowed("Dashboard"));
        assert!(!openai_component_allowed(""));
    }
}
