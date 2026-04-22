---
name: heimdall-rust-test-runner
description: Use when running, choosing, or triaging Rust and TypeScript verification commands in Heimdall after code changes. Covers targeted cargo test selection, lint and format checks, UI type checks, and failure triage.
---

# Heimdall Rust Test Runner

Use this skill for verification work in the Heimdall repo.

## Trigger guidance

- Use it when the task asks to run tests, validate a change, or choose the right Rust or UI verification command.
- Prefer it after meaningful Rust edits and before handoff on non-trivial changes.
- Do not use it for code review-only requests that do not require running checks.

## Suite selection

Choose the narrowest useful command first:

| Changed files | Command |
| --- | --- |
| `pricing.rs` | `cargo test pricing -- --nocapture` |
| `scanner/` | `cargo test scanner -- --nocapture` |
| `oauth/` | `cargo test oauth -- --nocapture` |
| `server/` | `cargo test server -- --nocapture` |
| `config.rs` | `cargo test config -- --nocapture` |
| `webhooks.rs` | `cargo test webhooks -- --nocapture` |
| `agent_status/` | `cargo test agent_status -- --nocapture` |
| `main.rs` or `cli_tests.rs` | `cargo test cli_tests -- --nocapture` |
| `optimizer/` | `cargo test optimizer -- --nocapture` |
| `scheduler/` | `cargo test scheduler -- --nocapture` |
| `hook/` | `cargo test hook -- --nocapture` |
| `classifier.rs` | `cargo test classifier -- --nocapture` |
| `watcher.rs` | `cargo test watcher -- --nocapture` |
| `src/ui/` or TS-only changes | `./node_modules/.bin/tsc --noEmit` |
| Multiple modules or unclear scope | `cargo test -- --nocapture` |

## Required workflow

1. Identify the changed surface from the diff or user request.
2. Run the targeted suite first for fast feedback.
3. If the change is broad, cross-cutting, or near handoff, follow with `cargo test`.
4. If formatting or linting was part of the request, run `cargo fmt --check` and `cargo clippy -- -D warnings`.
5. If `src/ui/` changed, run `./node_modules/.bin/tsc --noEmit`; if UI assets changed too, ensure the committed build artifacts were updated.

## Failure triage

- Compilation failure: fix the code, not the test.
- Assertion failure: compare expected vs actual and decide whether behavior or test expectations are wrong.
- Timeout or hang: inspect for deadlocks, watcher debounce issues, or long-running loops.
- Suspected flake: rerun the narrow failing command before broadening the investigation.

## Output expectations

- Report the command or commands run.
- Summarize only the failing suites or the clean pass result.
- If full verification was skipped, say exactly what remains unverified.
