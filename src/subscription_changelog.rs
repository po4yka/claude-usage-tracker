//! Curated changelog of provider subscription-policy changes.
//!
//! Anthropic and OpenAI rarely publish quota numbers and never publish a
//! machine-readable history of plan changes. This module ships a small
//! hand-curated timeline that the dashboard renders as annotations on the
//! subscription-quota history chart, with `source_url` for traceability.

use std::sync::OnceLock;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ChangelogEntry {
    pub date: String,
    pub provider: String,
    pub kind: String,
    pub title: String,
    pub description: String,
    pub source_url: String,
}

const RAW_JSON: &str = include_str!("data/subscription_changelog.json");

static CACHE: OnceLock<Vec<ChangelogEntry>> = OnceLock::new();

/// Load the curated changelog. Parsed once via OnceLock; subsequent calls
/// return a cheap reference clone.
pub fn load() -> Vec<ChangelogEntry> {
    CACHE.get_or_init(parse_or_empty).clone()
}

fn parse_or_empty() -> Vec<ChangelogEntry> {
    match serde_json::from_str::<Vec<ChangelogEntry>>(RAW_JSON) {
        Ok(mut entries) => {
            entries.sort_by(|a, b| a.date.cmp(&b.date));
            entries
        }
        Err(err) => {
            tracing::warn!("subscription_changelog parse failed: {err}");
            Vec::new()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_seed_data() {
        let entries = load();
        assert!(
            entries.len() >= 6,
            "expected ≥6 seed entries, got {}",
            entries.len()
        );
    }

    #[test]
    fn entries_are_sorted_by_date() {
        let entries = load();
        for window in entries.windows(2) {
            assert!(
                window[0].date <= window[1].date,
                "changelog must be sorted ascending by date"
            );
        }
    }

    #[test]
    fn entries_cover_both_providers() {
        let entries = load();
        assert!(entries.iter().any(|e| e.provider == "claude"));
        assert!(entries.iter().any(|e| e.provider == "codex"));
    }

    #[test]
    fn every_entry_has_source_url() {
        let entries = load();
        for entry in &entries {
            assert!(
                !entry.source_url.is_empty(),
                "entry missing source_url: {entry:?}"
            );
        }
    }
}
