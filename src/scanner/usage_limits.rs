//! Usage-limits file parser for Phase 20.
//!
//! Claude Code periodically writes `*-usage-limits` files under `~/.claude/`
//! and `~/.claude/projects/`. Each is a JSON object containing rate-window
//! data (percentage consumed, reset timestamp) for short (five-hour) and
//! weekly (seven-day) windows.
//!
//! This module:
//! 1. Discovers all matching files under a given `claude_dir`.
//! 2. Parses each file into a `UsageLimitsSnapshot` (soft failures → `None`).
//! 3. Provides a DB insertion helper that deduplicates against the most-recent
//!    row in `rate_window_history` per (source_path, window_type).
//!
//! All parse errors are logged at `debug!` and return `None` — the caller is
//! never expected to handle parse failures.

use std::path::{Path, PathBuf};
use std::time::UNIX_EPOCH;

use anyhow::Result;
use rusqlite::Connection;
use serde::Deserialize;
use tracing::debug;
use walkdir::WalkDir;

// ── Public types ──────────────────────────────────────────────────────────────

/// Parsed snapshot of a single `*-usage-limits` file.
#[derive(Debug, Clone, PartialEq)]
pub struct UsageLimitsSnapshot {
    /// Absolute path to the source file.
    pub source_path: PathBuf,
    /// File modification time as Unix seconds (f64 for sub-second precision).
    pub mtime: Option<f64>,
    /// Five-hour window: percentage consumed (0.0–100.0).
    pub five_hour_pct: Option<f64>,
    /// Five-hour window: ISO 8601 reset timestamp.
    pub five_hour_resets_at: Option<String>,
    /// Seven-day window: percentage consumed (0.0–100.0).
    pub seven_day_pct: Option<f64>,
    /// Seven-day window: ISO 8601 reset timestamp.
    pub seven_day_resets_at: Option<String>,
}

// ── Internal deserialization types ───────────────────────────────────────────

/// Flexible deserializer that accepts both `used_percent` and `percent_used`
/// field names and silently ignores unknown keys.
#[derive(Debug, Deserialize)]
struct WindowEntry {
    #[serde(alias = "percent_used")]
    used_percent: Option<f64>,
    resets_at: Option<String>,
}

/// Top-level shape of a usage-limits JSON file.
/// Both fields are optional so a file with only one window parses without error.
#[derive(Debug, Deserialize, Default)]
struct UsageLimitsFile {
    five_hour: Option<WindowEntry>,
    seven_day: Option<WindowEntry>,
}

// ── Public functions ──────────────────────────────────────────────────────────

/// Walk `claude_dir` and return paths of every file whose name ends with
/// `-usage-limits` (no extension).
///
/// Probes two subtrees:
/// - `<claude_dir>/*-usage-limits`  (top-level)
/// - `<claude_dir>/projects/**/*-usage-limits`
///
/// Returns an empty Vec when `claude_dir` does not exist.
pub fn discover_usage_limits_files(claude_dir: &Path) -> Vec<PathBuf> {
    if !claude_dir.exists() {
        return vec![];
    }

    let mut found = Vec::new();

    // Walk the entire claude_dir; a two-level probe is too restrictive since
    // project directories can nest arbitrarily.
    for entry in WalkDir::new(claude_dir)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if !entry.file_type().is_file() {
            continue;
        }
        let file_name = entry.file_name().to_string_lossy();
        if file_name.ends_with("-usage-limits") {
            found.push(entry.path().to_path_buf());
        }
    }

    found.sort();
    found
}

/// Parse a `*-usage-limits` JSON file into a [`UsageLimitsSnapshot`].
///
/// Returns `None` on any I/O or parse error; errors are logged at `debug!`.
pub fn parse_usage_limits(path: &Path) -> Option<UsageLimitsSnapshot> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| debug!("usage_limits: read error {}: {}", path.display(), e))
        .ok()?;

    let parsed: UsageLimitsFile = serde_json::from_str(&content)
        .map_err(|e| debug!("usage_limits: parse error {}: {}", path.display(), e))
        .ok()?;

    let mtime = std::fs::metadata(path)
        .ok()
        .and_then(|m| m.modified().ok())
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_secs_f64());

    Some(UsageLimitsSnapshot {
        source_path: path.to_path_buf(),
        mtime,
        five_hour_pct: parsed.five_hour.as_ref().and_then(|w| w.used_percent),
        five_hour_resets_at: parsed.five_hour.as_ref().and_then(|w| w.resets_at.clone()),
        seven_day_pct: parsed.seven_day.as_ref().and_then(|w| w.used_percent),
        seven_day_resets_at: parsed.seven_day.as_ref().and_then(|w| w.resets_at.clone()),
    })
}

// ── Database helpers ──────────────────────────────────────────────────────────

/// Insert usage-limits snapshot rows into `rate_window_history`.
///
/// Inserts one row per window type that has data. Skips insertion when the
/// most-recent row for (source_path, window_type) already has identical
/// `used_percent` and `resets_at` values (deduplication).
///
/// `source_kind` is stored in the row to distinguish `"file"` entries from
/// `"oauth"` entries.
pub fn insert_usage_limits_snapshot(
    conn: &Connection,
    snapshot: &UsageLimitsSnapshot,
    now_iso: &str,
) -> Result<()> {
    let source_path = snapshot.source_path.to_string_lossy();

    // Helper closure: insert one window row if not a duplicate.
    let insert_window =
        |window_type: &str, used_pct: Option<f64>, resets_at: Option<&str>| -> Result<()> {
            let (Some(pct), Some(resets)) = (used_pct, resets_at) else {
                return Ok(());
            };

            // Check most-recent row for this (source_path, window_type).
            let existing: Option<(f64, String)> = conn
                .query_row(
                    "SELECT used_percent, resets_at
                 FROM rate_window_history
                 WHERE window_type = ?1
                   AND source_kind = 'file'
                   AND source_path = ?2
                 ORDER BY id DESC
                 LIMIT 1",
                    rusqlite::params![window_type, source_path.as_ref()],
                    |row| Ok((row.get::<_, f64>(0)?, row.get::<_, String>(1)?)),
                )
                .ok();

            if let Some((prev_pct, ref prev_resets)) = existing {
                let same_pct = (prev_pct - pct).abs() < 0.001;
                let same_resets = prev_resets.as_str() == resets;
                if same_pct && same_resets {
                    debug!(
                        "usage_limits: skipping duplicate row for {} / {}",
                        source_path, window_type
                    );
                    return Ok(());
                }
            }

            conn.execute(
                "INSERT INTO rate_window_history
                 (timestamp, window_type, used_percent, resets_at, source_kind, source_path)
             VALUES (?1, ?2, ?3, ?4, 'file', ?5)",
                rusqlite::params![now_iso, window_type, pct, resets, source_path.as_ref()],
            )?;

            debug!(
                "usage_limits: inserted {} / {} = {:.1}%",
                source_path, window_type, pct
            );
            Ok(())
        };

    insert_window(
        "five_hour",
        snapshot.five_hour_pct,
        snapshot.five_hour_resets_at.as_deref(),
    )?;
    insert_window(
        "seven_day",
        snapshot.seven_day_pct,
        snapshot.seven_day_resets_at.as_deref(),
    )?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use std::io::Write;
    use tempfile::{NamedTempFile, TempDir};

    use super::*;

    // ── parse_usage_limits tests ──────────────────────────────────────────────

    #[test]
    fn parse_both_fields_present() {
        let json = r#"
        {
            "five_hour": { "used_percent": 42.5, "resets_at": "2026-04-18T18:00:00Z" },
            "seven_day": { "used_percent": 18.3, "resets_at": "2026-04-25T00:00:00Z" }
        }
        "#;
        let mut f = NamedTempFile::new().unwrap();
        f.write_all(json.as_bytes()).unwrap();
        f.flush().unwrap();

        let snap = parse_usage_limits(f.path()).unwrap();
        assert!((snap.five_hour_pct.unwrap() - 42.5).abs() < 0.01);
        assert_eq!(
            snap.five_hour_resets_at.as_deref(),
            Some("2026-04-18T18:00:00Z")
        );
        assert!((snap.seven_day_pct.unwrap() - 18.3).abs() < 0.01);
        assert_eq!(
            snap.seven_day_resets_at.as_deref(),
            Some("2026-04-25T00:00:00Z")
        );
    }

    #[test]
    fn parse_only_five_hour() {
        let json = r#"
        {
            "five_hour": { "used_percent": 55.0, "resets_at": "2026-04-18T18:00:00Z" }
        }
        "#;
        let mut f = NamedTempFile::new().unwrap();
        f.write_all(json.as_bytes()).unwrap();
        f.flush().unwrap();

        let snap = parse_usage_limits(f.path()).unwrap();
        assert!(snap.five_hour_pct.is_some());
        assert!(snap.seven_day_pct.is_none());
        assert!(snap.seven_day_resets_at.is_none());
    }

    #[test]
    fn parse_malformed_json_returns_none() {
        let mut f = NamedTempFile::new().unwrap();
        f.write_all(b"{ not valid json").unwrap();
        f.flush().unwrap();

        let result = parse_usage_limits(f.path());
        assert!(
            result.is_none(),
            "malformed JSON should return None, not panic"
        );
    }

    #[test]
    fn parse_empty_json_object() {
        let mut f = NamedTempFile::new().unwrap();
        f.write_all(b"{}").unwrap();
        f.flush().unwrap();

        let snap = parse_usage_limits(f.path()).unwrap();
        assert!(snap.five_hour_pct.is_none());
        assert!(snap.seven_day_pct.is_none());
    }

    #[test]
    fn parse_accepts_percent_used_alias() {
        let json = r#"
        {
            "five_hour": { "percent_used": 33.0, "resets_at": "2026-04-18T18:00:00Z" }
        }
        "#;
        let mut f = NamedTempFile::new().unwrap();
        f.write_all(json.as_bytes()).unwrap();
        f.flush().unwrap();

        let snap = parse_usage_limits(f.path()).unwrap();
        assert!((snap.five_hour_pct.unwrap() - 33.0).abs() < 0.01);
    }

    #[test]
    fn parse_missing_file_returns_none() {
        let result = parse_usage_limits(std::path::Path::new("/nonexistent/path-usage-limits"));
        assert!(result.is_none());
    }

    // ── discover_usage_limits_files tests ────────────────────────────────────

    #[test]
    fn discover_finds_usage_limits_files() {
        let dir = TempDir::new().unwrap();
        let projects = dir.path().join("projects").join("myproject");
        std::fs::create_dir_all(&projects).unwrap();

        // Create matching files.
        std::fs::write(dir.path().join("abc-usage-limits"), b"{}").unwrap();
        std::fs::write(projects.join("xyz-usage-limits"), b"{}").unwrap();
        // Create non-matching file.
        std::fs::write(dir.path().join("settings.json"), b"{}").unwrap();

        let found = discover_usage_limits_files(dir.path());
        assert_eq!(found.len(), 2, "should find exactly 2 usage-limits files");
    }

    #[test]
    fn discover_returns_empty_for_nonexistent_dir() {
        let found = discover_usage_limits_files(std::path::Path::new("/nonexistent/claude-dir"));
        assert!(found.is_empty());
    }

    // ── DB insertion tests ────────────────────────────────────────────────────

    fn make_test_db() -> (tempfile::TempDir, rusqlite::Connection) {
        use crate::scanner::db::{init_db, open_db};
        let tmp = TempDir::new().unwrap();
        let db_path = tmp.path().join("test.db");
        let conn = open_db(&db_path).unwrap();
        init_db(&conn).unwrap();
        (tmp, conn)
    }

    #[test]
    fn insert_snapshot_adds_rows() {
        let (_tmp, conn) = make_test_db();

        let snap = UsageLimitsSnapshot {
            source_path: std::path::PathBuf::from("/fake/abc-usage-limits"),
            mtime: Some(1234567890.0),
            five_hour_pct: Some(42.5),
            five_hour_resets_at: Some("2026-04-18T18:00:00Z".into()),
            seven_day_pct: Some(18.3),
            seven_day_resets_at: Some("2026-04-25T00:00:00Z".into()),
        };

        insert_usage_limits_snapshot(&conn, &snap, "2026-04-17T12:00:00Z").unwrap();

        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM rate_window_history", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 2, "two windows → two rows");

        // Verify source_kind = 'file'
        let kind: String = conn
            .query_row(
                "SELECT source_kind FROM rate_window_history WHERE window_type = 'five_hour'",
                [],
                |r| r.get(0),
            )
            .unwrap();
        assert_eq!(kind, "file");
    }

    #[test]
    fn insert_snapshot_deduplicates() {
        let (_tmp, conn) = make_test_db();

        let snap = UsageLimitsSnapshot {
            source_path: std::path::PathBuf::from("/fake/abc-usage-limits"),
            mtime: Some(1234567890.0),
            five_hour_pct: Some(42.5),
            five_hour_resets_at: Some("2026-04-18T18:00:00Z".into()),
            seven_day_pct: None,
            seven_day_resets_at: None,
        };

        insert_usage_limits_snapshot(&conn, &snap, "2026-04-17T12:00:00Z").unwrap();
        // Insert the same snapshot again — should be a no-op.
        insert_usage_limits_snapshot(&conn, &snap, "2026-04-17T12:01:00Z").unwrap();

        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM rate_window_history", [], |r| r.get(0))
            .unwrap();
        assert_eq!(
            count, 1,
            "duplicate snapshot should not insert a second row"
        );
    }

    #[test]
    fn insert_snapshot_inserts_when_values_change() {
        let (_tmp, conn) = make_test_db();

        let snap1 = UsageLimitsSnapshot {
            source_path: std::path::PathBuf::from("/fake/abc-usage-limits"),
            mtime: Some(1234567890.0),
            five_hour_pct: Some(42.5),
            five_hour_resets_at: Some("2026-04-18T18:00:00Z".into()),
            seven_day_pct: None,
            seven_day_resets_at: None,
        };
        let snap2 = UsageLimitsSnapshot {
            five_hour_pct: Some(55.0),
            ..snap1.clone()
        };

        insert_usage_limits_snapshot(&conn, &snap1, "2026-04-17T12:00:00Z").unwrap();
        insert_usage_limits_snapshot(&conn, &snap2, "2026-04-17T12:30:00Z").unwrap();

        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM rate_window_history", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 2, "changed percentage should produce a new row");
    }
}
