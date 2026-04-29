/// Binary entry point for `heimdall-hook`.
///
/// Thin wrapper around `hook::main_impl()` from the shared library crate.
///
/// Exit contract:
/// - ALWAYS exits 0 — a non-zero exit would surface an error dialog to the user.
/// - ALWAYS prints `{}` on stdout.
/// - NEVER blocks for more than 1 second (stdin read is guarded by a timeout).
/// - NEVER propagates a panic — `catch_unwind` absorbs any panic from upstream
///   code (rusqlite, serde, etc.), logs it to stderr, and still emits `{}`.
fn main() {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "warn".into()),
        )
        .init();

    // Wrap the entire hook body in catch_unwind so that panics from any
    // dependency (rusqlite, serde, …) cannot propagate to the Claude Code
    // process.  On panic we log to stderr (visible in debug logs) and still
    // emit `{}` on stdout so the hook contract is upheld.
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        claude_usage_tracker::hook::main_impl();
    }));

    if let Err(payload) = result {
        // Extract a human-readable message from the panic payload.
        let msg = payload
            .downcast_ref::<&str>()
            .copied()
            .or_else(|| payload.downcast_ref::<String>().map(String::as_str))
            .unwrap_or("<non-string panic payload>");
        tracing::error!("heimdall-hook: panic caught, aborting cleanly: {}", msg);
        print!("{{}}");
    }

    std::process::exit(0);
}
