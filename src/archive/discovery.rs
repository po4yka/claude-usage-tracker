//! Walks each provider's `archive_paths()` and yields candidate files for
//! snapshotting.

use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::Result;
use walkdir::WalkDir;

use crate::scanner::provider::Provider;

#[derive(Debug)]
pub struct DiscoveredFile {
    /// Provider name, e.g. "claude".
    pub provider: &'static str,
    /// The provider's root that contains `absolute_path`.
    pub root: PathBuf,
    /// Absolute path to the file on disk.
    pub absolute_path: PathBuf,
    /// Path relative to `root`, slash-separated.
    pub logical_path: String,
}

/// Walk every root reported by every provider and yield each regular file.
pub fn discover(providers: &[Arc<dyn Provider>]) -> Result<Vec<DiscoveredFile>> {
    let mut out = Vec::new();
    for provider in providers {
        for root in provider.archive_paths() {
            if !root.exists() {
                continue;
            }
            collect_under_root(provider.name(), &root, &mut out)?;
        }
    }
    Ok(out)
}

fn collect_under_root(
    provider: &'static str,
    root: &Path,
    out: &mut Vec<DiscoveredFile>,
) -> Result<()> {
    for entry in WalkDir::new(root).follow_links(false) {
        let entry = match entry {
            Ok(e) => e,
            Err(e) => {
                tracing::warn!("archive discover: walk error under {}: {}", root.display(), e);
                continue;
            }
        };
        if !entry.file_type().is_file() {
            continue;
        }
        let abs = entry.path().to_path_buf();
        let logical = match abs.strip_prefix(root) {
            Ok(rel) => rel.to_string_lossy().replace(std::path::MAIN_SEPARATOR, "/"),
            Err(_) => continue,
        };
        out.push(DiscoveredFile {
            provider,
            root: root.to_path_buf(),
            absolute_path: abs,
            logical_path: logical,
        });
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn collect_under_root_finds_nested_files() {
        let tmp = TempDir::new().unwrap();
        let root = tmp.path();
        fs::create_dir_all(root.join("a/b")).unwrap();
        fs::write(root.join("top.jsonl"), b"x").unwrap();
        fs::write(root.join("a/mid.jsonl"), b"y").unwrap();
        fs::write(root.join("a/b/deep.jsonl"), b"z").unwrap();

        let mut out = Vec::new();
        collect_under_root("test", root, &mut out).unwrap();
        let logicals: Vec<&str> = out.iter().map(|f| f.logical_path.as_str()).collect();
        assert_eq!(logicals.len(), 3);
        assert!(logicals.contains(&"top.jsonl"));
        assert!(logicals.contains(&"a/mid.jsonl"));
        assert!(logicals.contains(&"a/b/deep.jsonl"));
    }
}
