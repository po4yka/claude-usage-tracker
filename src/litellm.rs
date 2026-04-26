/// LiteLLM model pricing catalogue — fetch, cache, and load.
///
/// Architecture mirrors `currency.rs`:
/// - Blocking public API over a `new_current_thread` tokio runtime
/// - File cache at `~/.cache/heimdall/litellm_pricing.json` with age tracking
/// - Offline-safe: if fetch fails, callers get `None` and fall back to static table
/// - Test seam via `fetch_fn` injection — no network in tests
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::Duration;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;

const LITELLM_URL: &str =
    "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json";
const FETCH_TIMEOUT_SECS: u64 = 5;

// ── Cache shape ───────────────────────────────────────────────────────────────

/// A single model's pricing as recorded from LiteLLM.
/// Fields are per-million-token rates in USD (same unit as `ModelPricing`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LiteLlmModelEntry {
    /// Input cost per million tokens (USD).
    pub input_cost_per_token: Option<f64>,
    /// Output cost per million tokens (USD).
    pub output_cost_per_token: Option<f64>,
}

/// What we persist to `~/.cache/heimdall/litellm_pricing.json`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LiteLlmSnapshot {
    /// RFC 3339 timestamp of when the data was fetched.
    pub fetched_at: String,
    /// Map of model key → pricing entry.
    pub entries: HashMap<String, LiteLlmModelEntry>,
}

impl LiteLlmSnapshot {
    /// Age of this snapshot in hours from now.
    pub fn age_hours(&self) -> f64 {
        let fetched = self
            .fetched_at
            .parse::<DateTime<Utc>>()
            .unwrap_or(Utc::now());
        let elapsed = Utc::now().signed_duration_since(fetched);
        elapsed.num_seconds() as f64 / 3600.0
    }
}

// ── Errors ───────────────────────────────────────────────────────────────────

#[derive(Debug, Error)]
pub enum LiteLlmError {
    #[error("HTTP fetch failed: {0}")]
    Http(#[from] reqwest::Error),
    #[error("Cache IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Cache parse error: {0}")]
    Parse(#[from] serde_json::Error),
}

// ── Cache path ────────────────────────────────────────────────────────────────

/// Production cache path: `~/.cache/heimdall/litellm_pricing.json`
pub fn cache_path() -> PathBuf {
    dirs::cache_dir()
        .unwrap_or_else(|| PathBuf::from(".cache"))
        .join("heimdall")
        .join("litellm_pricing.json")
}

// ── Cache read/write ──────────────────────────────────────────────────────────

/// Read the cached snapshot from `path`. Returns `None` if absent or unparseable.
pub fn read_cache(path: &Path) -> Option<LiteLlmSnapshot> {
    let bytes = std::fs::read(path).ok()?;
    serde_json::from_slice(&bytes).ok()
}

/// Write a snapshot to `path`, creating parent directories as needed.
pub fn write_cache(path: &Path, snapshot: &LiteLlmSnapshot) -> Result<(), LiteLlmError> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let json = serde_json::to_vec_pretty(snapshot)?;
    std::fs::write(path, json)?;
    Ok(())
}

// ── Live fetch ────────────────────────────────────────────────────────────────

/// Fetch the LiteLLM catalogue from GitHub and return a snapshot.
/// Blocking — spawns a single-thread tokio runtime internally.
/// Returns `None` on any network or parse error.
pub fn fetch_live() -> Option<LiteLlmSnapshot> {
    fetch_from_url(LITELLM_URL)
}

/// Fetch from an arbitrary URL — used internally and for testing.
pub fn fetch_from_url(url: &str) -> Option<LiteLlmSnapshot> {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .ok()?;
    rt.block_on(async {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(FETCH_TIMEOUT_SECS))
            .build()
            .ok()?;
        let resp = client.get(url).send().await.ok()?;
        // The LiteLLM JSON is a flat object: { "model-name": { fields... }, ... }
        let raw: HashMap<String, serde_json::Value> = resp.json().await.ok()?;
        let entries = parse_raw_catalogue(raw);
        Some(LiteLlmSnapshot {
            fetched_at: Utc::now().to_rfc3339(),
            entries,
        })
    })
}

/// Parse the raw LiteLLM catalogue JSON into our model entry map.
/// The catalogue has a "sample_spec" meta-entry and various other non-model
/// keys — we parse all entries defensively (missing cost fields become None).
fn parse_raw_catalogue(
    raw: HashMap<String, serde_json::Value>,
) -> HashMap<String, LiteLlmModelEntry> {
    raw.into_iter()
        .map(|(key, value)| {
            let input_cost_per_token = value
                .get("input_cost_per_token")
                .and_then(|v| v.as_f64())
                .map(|per_token| per_token * 1_000_000.0); // convert per-token → per-MTok
            let output_cost_per_token = value
                .get("output_cost_per_token")
                .and_then(|v| v.as_f64())
                .map(|per_token| per_token * 1_000_000.0);
            (
                key,
                LiteLlmModelEntry {
                    input_cost_per_token,
                    output_cost_per_token,
                },
            )
        })
        .collect()
}

// ── Refresh command helper ────────────────────────────────────────────────────

/// Fetch the LiteLLM catalogue, write cache, and return a summary string.
/// Used by the `pricing refresh` subcommand.
/// Returns `(model_count, cache_path)` on success, error string on failure.
pub fn run_refresh(cache: &Path) -> Result<(usize, PathBuf), String> {
    match fetch_live() {
        Some(snapshot) => {
            let count = snapshot.entries.len();
            write_cache(cache, &snapshot).map_err(|e| e.to_string())?;
            Ok((count, cache.to_path_buf()))
        }
        None => Err("network fetch failed or timed out".to_string()),
    }
}

/// Same as `run_refresh` but accepts an injected snapshot — for tests only.
#[allow(dead_code)]
pub fn run_refresh_with_snapshot(
    cache: &Path,
    snapshot: LiteLlmSnapshot,
) -> Result<(usize, PathBuf), String> {
    let count = snapshot.entries.len();
    write_cache(cache, &snapshot).map_err(|e| e.to_string())?;
    Ok((count, cache.to_path_buf()))
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn make_snapshot(entries: &[(&str, f64, f64)]) -> LiteLlmSnapshot {
        let mut map = HashMap::new();
        for (name, input, output) in entries {
            map.insert(
                name.to_string(),
                LiteLlmModelEntry {
                    input_cost_per_token: Some(*input),
                    output_cost_per_token: Some(*output),
                },
            );
        }
        LiteLlmSnapshot {
            fetched_at: Utc::now().to_rfc3339(),
            entries: map,
        }
    }

    #[test]
    fn test_cache_round_trip() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("litellm_pricing.json");
        let snap = make_snapshot(&[("gemini-2.5-flash", 0.075, 0.30)]);
        write_cache(&path, &snap).unwrap();
        let loaded = read_cache(&path).unwrap();
        assert!(loaded.entries.contains_key("gemini-2.5-flash"));
        let entry = &loaded.entries["gemini-2.5-flash"];
        assert!((entry.input_cost_per_token.unwrap() - 0.075).abs() < 1e-9);
        assert!((entry.output_cost_per_token.unwrap() - 0.30).abs() < 1e-9);
    }

    #[test]
    fn test_cache_creates_parent_dirs() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("a").join("b").join("litellm_pricing.json");
        let snap = make_snapshot(&[("gemini-2.5-flash", 0.075, 0.30)]);
        write_cache(&path, &snap).unwrap();
        assert!(path.exists());
    }

    #[test]
    fn test_read_cache_missing_returns_none() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("litellm_pricing.json");
        assert!(read_cache(&path).is_none());
    }

    #[test]
    fn test_run_refresh_with_snapshot() {
        let tmp = TempDir::new().unwrap();
        let path = tmp.path().join("litellm_pricing.json");
        let snap = make_snapshot(&[
            ("gemini-2.5-flash", 0.075, 0.30),
            ("gemini-2.5-pro", 1.25, 5.0),
            ("mistral-large", 2.0, 6.0),
        ]);
        let (count, written_path) = run_refresh_with_snapshot(&path, snap).unwrap();
        assert_eq!(count, 3);
        assert_eq!(written_path, path);
        assert!(path.exists());
    }

    #[test]
    fn test_parse_raw_catalogue_converts_per_token_to_per_mtok() {
        // LiteLLM stores per-token rates; we convert to per-MTok on load.
        // $0.000_000_075 per token → $0.075 per MTok
        let mut raw: HashMap<String, serde_json::Value> = HashMap::new();
        raw.insert(
            "gemini-2.5-flash".to_string(),
            serde_json::json!({
                "input_cost_per_token": 0.000_000_075_f64,
                "output_cost_per_token": 0.000_000_30_f64,
            }),
        );
        let entries = parse_raw_catalogue(raw);
        let e = &entries["gemini-2.5-flash"];
        // 0.000_000_075 * 1_000_000 = 0.075
        assert!((e.input_cost_per_token.unwrap() - 0.075).abs() < 1e-7);
        assert!((e.output_cost_per_token.unwrap() - 0.30).abs() < 1e-7);
    }
}
