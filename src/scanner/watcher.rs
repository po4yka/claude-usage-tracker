//! File-watcher auto-refresh for Phase 20.
//!
//! `FileWatcher` monitors a set of directories for `.jsonl` `Write`/`Create`
//! events, coalesces bursts over a 2-second debounce window, and fires a
//! caller-supplied callback once per burst.
//!
//! Design choices:
//! - Uses the `notify` crate (v7) for cross-platform filesystem notifications.
//! - All debounce logic lives in a dedicated OS thread so the caller is not
//!   required to run an async runtime.
//! - The `on_change` closure is called at most once per 2-second window
//!   regardless of how many `.jsonl` files are touched.
//! - A shutdown channel (`std::sync::mpsc`) lets `stop()` cleanly terminate
//!   the watcher thread.
//! - Directories that disappear after startup are logged at `warn!` and do
//!   not terminate the watcher.

use std::path::PathBuf;
use std::sync::{Arc, Mutex, mpsc};
use std::thread;
use std::time::Duration;

use anyhow::Result;
use notify::{Event, EventKind, RecursiveMode, Watcher};
use tracing::{debug, warn};

const DEBOUNCE_WINDOW: Duration = Duration::from_secs(2);

/// Opaque handle to a running file-watcher.
///
/// Drop or call [`FileWatcher::stop`] to terminate the background thread.
pub struct FileWatcher {
    /// Sender half of the shutdown channel. Wrapped in Option so it can be
    /// taken in `stop()` without conflicting with the `Drop` impl.
    shutdown_tx: Option<mpsc::Sender<()>>,
    /// Join handle for the watcher thread.
    thread: Option<thread::JoinHandle<()>>,
}

impl FileWatcher {
    /// Start watching `paths` (each watched recursively).
    ///
    /// `on_change` fires once per debounced burst (2-second window). It is
    /// called from the internal thread, so it must be `Send + Sync`.
    pub fn start(
        paths: Vec<PathBuf>,
        on_change: Box<dyn Fn() + Send + Sync + 'static>,
    ) -> Result<Self> {
        let on_change = Arc::new(on_change);

        // Channel used to forward raw notify events into the debounce thread.
        let (event_tx, event_rx) = mpsc::channel::<()>();

        // Shutdown signal: when the Sender is dropped the Receiver side
        // unblocks and the thread exits.
        let (shutdown_tx, shutdown_rx) = mpsc::channel::<()>();

        // Clone event_tx for the notify callback (which requires 'static).
        let event_tx_clone = event_tx.clone();

        // Build the notify watcher. The callback filters to Write/Create on
        // .jsonl files and forwards a unit token to the debounce loop.
        let mut watcher = notify::recommended_watcher(move |res: notify::Result<Event>| {
            match res {
                Ok(event) => {
                    let is_relevant =
                        matches!(event.kind, EventKind::Create(_) | EventKind::Modify(_))
                            && event
                                .paths
                                .iter()
                                .any(|p| p.extension().is_some_and(|ext| ext == "jsonl"));

                    if is_relevant {
                        debug!("watcher: relevant event on {:?}", event.paths);
                        // Best-effort send; ignore send errors (receiver may
                        // have gone away during shutdown).
                        let _ = event_tx_clone.send(());
                    }
                }
                Err(e) => {
                    warn!("watcher: notify error: {}", e);
                }
            }
        })?;

        // Register each path; log a warning for paths that don't exist yet.
        for path in &paths {
            if let Err(e) = watcher.watch(path, RecursiveMode::Recursive) {
                warn!("watcher: cannot watch {}: {}", path.display(), e);
            } else {
                debug!("watcher: watching {}", path.display());
            }
        }

        let thread = thread::spawn(move || {
            // Keep the watcher alive for the lifetime of the thread.
            let _watcher = watcher;

            // Returns true when either a shutdown signal arrived (Ok) or the
            // sender was dropped (Disconnected). Empty means "keep running."
            let is_shutdown = |rx: &mpsc::Receiver<()>| {
                matches!(
                    rx.try_recv(),
                    Ok(()) | Err(mpsc::TryRecvError::Disconnected)
                )
            };

            loop {
                // Poll events with a short timeout so shutdown is checked
                // frequently even when no filesystem events are arriving.
                let first = event_rx.recv_timeout(Duration::from_millis(200));

                if is_shutdown(&shutdown_rx) {
                    debug!("watcher: shutdown signal received");
                    break;
                }

                if first.is_err() {
                    // Timeout — no event yet; loop.
                    continue;
                }

                // Drain further events during the 2-second debounce window,
                // but keep checking the shutdown signal so we don't block
                // callers that drop the watcher mid-burst.
                let deadline = std::time::Instant::now() + DEBOUNCE_WINDOW;
                loop {
                    let remaining = deadline
                        .saturating_duration_since(std::time::Instant::now())
                        .min(Duration::from_millis(200));
                    if remaining.is_zero() {
                        break;
                    }
                    match event_rx.recv_timeout(remaining) {
                        Ok(()) => {}
                        Err(mpsc::RecvTimeoutError::Timeout) => {
                            if is_shutdown(&shutdown_rx) {
                                debug!("watcher: shutdown during debounce drain");
                                return;
                            }
                            if std::time::Instant::now() >= deadline {
                                break;
                            }
                        }
                        Err(mpsc::RecvTimeoutError::Disconnected) => {
                            debug!("watcher: event channel disconnected");
                            return;
                        }
                    }
                }

                if is_shutdown(&shutdown_rx) {
                    debug!("watcher: shutdown signal received before callback");
                    break;
                }

                debug!("watcher: debounce window elapsed — firing on_change");
                on_change();
            }

            debug!("watcher: thread exiting");
        });

        Ok(Self {
            shutdown_tx: Some(shutdown_tx),
            thread: Some(thread),
        })
    }

    /// Stop the watcher and block until the internal thread exits.
    pub fn stop(mut self) {
        // Drop the sender to signal the thread to exit.
        drop(self.shutdown_tx.take());
        if let Some(handle) = self.thread.take() {
            let _ = handle.join();
        }
    }
}

impl Drop for FileWatcher {
    fn drop(&mut self) {
        // Drop the sender first so the thread sees the shutdown signal,
        // then join to avoid leaving a dangling thread.
        drop(self.shutdown_tx.take());
        if let Some(handle) = self.thread.take() {
            let _ = handle.join();
        }
    }
}

/// Shared scan-lock used to ensure at most one scanner::scan() runs at a time
/// when the watcher triggers re-scans.
pub type ScanLock = Arc<Mutex<()>>;

/// Create a new scan-lock.
pub fn new_scan_lock() -> ScanLock {
    Arc::new(Mutex::new(()))
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::sync::Arc;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::time::Duration;

    use tempfile::TempDir;

    use super::FileWatcher;

    /// Helper: block until `counter` reaches at least `target` or `timeout`
    /// elapses.  Returns `true` if the target was reached.
    fn wait_for_count(counter: &Arc<AtomicUsize>, target: usize, timeout: Duration) -> bool {
        let deadline = std::time::Instant::now() + timeout;
        loop {
            if counter.load(Ordering::SeqCst) >= target {
                return true;
            }
            if std::time::Instant::now() >= deadline {
                return false;
            }
            std::thread::sleep(Duration::from_millis(50));
        }
    }

    #[test]
    fn watcher_fires_on_jsonl_create() {
        let dir = TempDir::new().unwrap();
        let counter = Arc::new(AtomicUsize::new(0));
        let counter_clone = counter.clone();

        let watcher = FileWatcher::start(
            vec![dir.path().to_path_buf()],
            Box::new(move || {
                counter_clone.fetch_add(1, Ordering::SeqCst);
            }),
        )
        .unwrap();

        // Touch a .jsonl file.
        let jsonl_path = dir.path().join("session.jsonl");
        fs::write(&jsonl_path, b"{}\n").unwrap();

        // on_change should fire within 3 seconds (2s debounce + slack).
        let fired = wait_for_count(&counter, 1, Duration::from_secs(3));
        assert!(fired, "on_change should fire after touching a .jsonl file");

        watcher.stop();
    }

    #[test]
    fn watcher_debounces_burst() {
        let dir = TempDir::new().unwrap();
        let counter = Arc::new(AtomicUsize::new(0));
        let counter_clone = counter.clone();

        let watcher = FileWatcher::start(
            vec![dir.path().to_path_buf()],
            Box::new(move || {
                counter_clone.fetch_add(1, Ordering::SeqCst);
            }),
        )
        .unwrap();

        // Touch 5 .jsonl files in quick succession.
        for i in 0..5 {
            let path = dir.path().join(format!("file{}.jsonl", i));
            fs::write(&path, b"{}\n").unwrap();
            std::thread::sleep(Duration::from_millis(50));
        }

        // After debounce window, only 1 callback should have fired.
        let fired = wait_for_count(&counter, 1, Duration::from_secs(4));
        assert!(fired, "on_change should fire at least once");

        // Give it extra time to ensure no second callback sneaks in.
        std::thread::sleep(Duration::from_millis(300));
        let count = counter.load(Ordering::SeqCst);
        assert_eq!(
            count, 1,
            "burst of 5 touches → exactly 1 debounced callback, got {count}"
        );

        watcher.stop();
    }

    #[test]
    fn watcher_ignores_non_jsonl_files() {
        let dir = TempDir::new().unwrap();
        let counter = Arc::new(AtomicUsize::new(0));
        let counter_clone = counter.clone();

        let watcher = FileWatcher::start(
            vec![dir.path().to_path_buf()],
            Box::new(move || {
                counter_clone.fetch_add(1, Ordering::SeqCst);
            }),
        )
        .unwrap();

        // Touch a non-.jsonl file.
        let txt_path = dir.path().join("notes.txt");
        fs::write(&txt_path, b"hello\n").unwrap();

        // Wait long enough to confirm no callback fires.
        std::thread::sleep(Duration::from_secs(3));
        let count = counter.load(Ordering::SeqCst);
        assert_eq!(count, 0, "non-.jsonl files should not trigger on_change");

        watcher.stop();
    }

    #[test]
    fn watcher_drop_exits_cleanly() {
        let dir = TempDir::new().unwrap();
        let watcher = FileWatcher::start(vec![dir.path().to_path_buf()], Box::new(|| {})).unwrap();

        // Dropping the watcher should not hang.
        drop(watcher);
        // If we reach here, the thread exited cleanly.
    }
}
