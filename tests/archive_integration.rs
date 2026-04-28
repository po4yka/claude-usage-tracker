use std::fs;
use std::path::PathBuf;
use std::sync::Arc;

use anyhow::Result;
use claude_usage_tracker::archive::Archive;
use claude_usage_tracker::archive::manifest::Manifest;
use claude_usage_tracker::scanner::provider::{Provider, SessionSource};
use tempfile::TempDir;

struct FixtureProvider {
    name: &'static str,
    roots: Vec<PathBuf>,
}

impl Provider for FixtureProvider {
    fn name(&self) -> &'static str {
        self.name
    }
    fn discover_sessions(&self) -> Result<Vec<SessionSource>> {
        Ok(vec![])
    }
    fn parse(
        &self,
        _path: &std::path::Path,
    ) -> Result<Vec<claude_usage_tracker::models::Turn>> {
        Ok(vec![])
    }
    fn archive_paths(&self) -> Vec<PathBuf> {
        self.roots.clone()
    }
}

#[test]
fn snapshot_writes_manifest_and_objects() {
    let tmp = TempDir::new().unwrap();
    let archive_root = tmp.path().join("archive");
    let provider_root = tmp.path().join("source");
    fs::create_dir_all(provider_root.join("proj-a")).unwrap();
    fs::write(provider_root.join("proj-a/sess.jsonl"), b"line1\nline2\n").unwrap();
    fs::write(provider_root.join("top.jsonl"), b"alpha\n").unwrap();

    let providers: Vec<Arc<dyn Provider>> = vec![Arc::new(FixtureProvider {
        name: "fixture",
        roots: vec![provider_root.clone()],
    })];

    let archive = Archive::at(archive_root.clone()).unwrap();
    let id = archive.snapshot(&providers).unwrap();

    let manifest_path = archive_root
        .join("snapshots")
        .join(&id)
        .join("manifest.json");
    assert!(manifest_path.is_file());
    let manifest: Manifest =
        serde_json::from_slice(&fs::read(&manifest_path).unwrap()).unwrap();
    assert_eq!(manifest.providers.len(), 1);
    assert_eq!(manifest.providers[0].files.len(), 2);

    // Object store has 2 files.
    let objects_dir = archive_root.join("objects").join("sha256");
    let count = walkdir::WalkDir::new(&objects_dir)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .count();
    assert_eq!(count, 2);
}

#[test]
fn snapshot_is_dedup_friendly_across_runs() {
    let tmp = TempDir::new().unwrap();
    let archive_root = tmp.path().join("archive");
    let provider_root = tmp.path().join("source");
    fs::create_dir_all(&provider_root).unwrap();
    fs::write(provider_root.join("a.jsonl"), b"static").unwrap();
    let providers: Vec<Arc<dyn Provider>> = vec![Arc::new(FixtureProvider {
        name: "fixture",
        roots: vec![provider_root.clone()],
    })];
    let archive = Archive::at(archive_root.clone()).unwrap();
    archive.snapshot(&providers).unwrap();
    archive.snapshot(&providers).unwrap();

    let count = walkdir::WalkDir::new(archive_root.join("objects").join("sha256"))
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .count();
    assert_eq!(count, 1, "identical content must dedupe to a single object");
}
