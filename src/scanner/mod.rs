pub mod db;
pub mod parser;
#[cfg(test)]
mod tests;

use std::path::{Path, PathBuf};

use anyhow::Result;
use tracing::{debug, info};
use walkdir::WalkDir;

use crate::models::ScanResult;
use db::{
    get_processed_file, init_db, insert_turns, open_db, recompute_session_totals,
    upsert_processed_file, upsert_sessions,
};
use parser::{aggregate_sessions, parse_jsonl_file};

fn home_dir() -> PathBuf {
    dirs::home_dir().unwrap_or_else(|| PathBuf::from("."))
}

fn default_projects_dirs() -> Vec<PathBuf> {
    let home = home_dir();
    let mut dirs = vec![home.join(".claude").join("projects")];
    #[cfg(target_os = "macos")]
    dirs.push(home.join("Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/projects"));
    dirs
}

pub fn default_db_path() -> PathBuf {
    home_dir().join(".claude").join("usage.db")
}

pub fn scan(
    projects_dirs: Option<Vec<PathBuf>>,
    db_path: &Path,
    verbose: bool,
) -> Result<ScanResult> {
    let conn = open_db(db_path)?;
    init_db(&conn)?;

    let dirs = projects_dirs.unwrap_or_else(default_projects_dirs);

    let mut jsonl_files: Vec<PathBuf> = Vec::new();
    for d in &dirs {
        if !d.exists() {
            continue;
        }
        if verbose {
            info!("Scanning {} ...", d.display());
        }
        for entry in WalkDir::new(d).into_iter().filter_map(|e| e.ok()) {
            if entry.path().extension().is_some_and(|ext| ext == "jsonl") {
                jsonl_files.push(entry.path().to_path_buf());
            }
        }
    }
    jsonl_files.sort();

    let mut result = ScanResult::default();
    let mut any_changes = false;

    for filepath in &jsonl_files {
        let filepath_str = filepath.to_string_lossy().to_string();
        let mtime = match std::fs::metadata(filepath) {
            Ok(m) => m
                .modified()
                .ok()
                .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
                .map(|d| d.as_secs_f64())
                .unwrap_or(0.0),
            Err(_) => continue,
        };

        let prev = get_processed_file(&conn, &filepath_str)?;

        if let Some((prev_mtime, _)) = prev
            && (prev_mtime - mtime).abs() < 0.01
        {
            result.skipped += 1;
            continue;
        }

        let is_new = prev.is_none();
        let skip_lines = if is_new { 0 } else { prev.unwrap().1 };

        debug!("[{}] {}", if is_new { "NEW" } else { "UPD" }, filepath_str);

        let parsed = parse_jsonl_file(filepath, skip_lines);

        // If file didn't grow, just update mtime
        if !is_new && parsed.line_count <= skip_lines {
            upsert_processed_file(&conn, &filepath_str, mtime, skip_lines)?;
            result.skipped += 1;
            continue;
        }

        if !parsed.turns.is_empty() || !parsed.session_metas.is_empty() {
            let sessions = aggregate_sessions(&parsed.session_metas, &parsed.turns);
            upsert_sessions(&conn, &sessions)?;
            insert_turns(&conn, &parsed.turns)?;
            result.sessions += sessions.len();
            result.turns += parsed.turns.len();
            any_changes = true;
        }

        if is_new {
            result.new += 1;
        } else {
            result.updated += 1;
        }

        upsert_processed_file(&conn, &filepath_str, mtime, parsed.line_count)?;
    }

    // Recompute session totals from turns for dedup correctness
    if any_changes {
        recompute_session_totals(&conn)?;
    }

    if verbose {
        info!(
            "Scan complete: {} new, {} updated, {} skipped, {} turns",
            result.new, result.updated, result.skipped, result.turns
        );
    }

    Ok(result)
}
