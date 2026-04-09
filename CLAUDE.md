# Claude Usage Tracker -- Development Guide

## Project

Local Claude Code usage analytics dashboard. Rust binary with embedded web UI.

## Build & Run

```bash
# TypeScript (dashboard UI) -- only needed when modifying src/ui/app.ts
npm install                                    # one-time: install esbuild + typescript
./node_modules/.bin/esbuild src/ui/app.ts \
  --outfile=src/ui/app.js --bundle \
  --format=iife --target=es2020                # compile TS -> JS

# Rust
cargo build                    # debug build
cargo build --release          # release build
cargo run -- dashboard         # scan + start dashboard
cargo run -- today             # today's usage
cargo run -- stats             # all-time stats
cargo run -- scan              # scan only
```

The compiled `src/ui/app.js` is committed to git so `cargo build` works without Node.js installed. Only re-run esbuild after editing `src/ui/app.ts`.

## Test

```bash
cargo test                     # all Rust tests
cargo test scanner             # scanner module tests
cargo test pricing             # pricing tests
cargo test -- --nocapture      # with stdout
./node_modules/.bin/tsc --noEmit  # TypeScript type check
```

## Lint

```bash
cargo clippy -- -D warnings
cargo fmt --check
```

## Architecture

```
src/
  main.rs              -- CLI (clap), entry point
  models.rs            -- Shared types (Session, Turn, ScanResult)
  pricing.rs           -- Pricing table, cost calculation (SINGLE source of truth)
  scanner/
    mod.rs             -- scan() orchestration, incremental logic
    parser.rs          -- JSONL parsing, streaming dedup by message.id
    db.rs              -- SQLite schema, init, migrations, queries
  server/
    mod.rs             -- axum server setup, router
    api.rs             -- GET /api/data, POST /api/rescan, GET /api/health
    assets.rs          -- include_str! for HTML/CSS/JS
  ui/
    index.html         -- Dashboard HTML
    style.css          -- Dashboard styles
    app.ts             -- Dashboard logic (TypeScript source)
    app.js             -- Compiled JS (committed, do not edit directly)
```

## Key Design Decisions

- **Single pricing source**: pricing.rs is the only place model prices are defined. The JS dashboard receives cost values pre-calculated from the API, or recalculates using a pricing table injected into the HTML template from Rust. Never duplicate pricing in JS.
- **Embedded assets**: HTML/CSS/JS are embedded via `include_str!` at compile time. No separate file serving.
- **TypeScript source**: `src/ui/app.ts` is the source of truth for dashboard JS. Compiled to `src/ui/app.js` via esbuild. The compiled JS is committed so `cargo build` works without Node.js.
- **Incremental scanning**: track file mtime + line count in `processed_files` table. Only re-read changed files, skip already-processed lines.
- **Dedup correctness**: after all turn inserts, recompute session totals from the turns table via `SELECT SUM(...)`. This handles cases where `INSERT OR IGNORE` skipped duplicate message_ids.
- **Atomic rescan**: on rescan, write to a temp DB file, then atomically rename over the old one. Never delete the DB then scan (crash = data loss).

## Conventions

- Use `thiserror` for error types, `anyhow` in main/CLI
- Prefer `&str` over `String` in function signatures where possible
- All SQL queries in `db.rs`, nowhere else
- Tests use `tempfile` crate for temp dirs and DB files
- No `.unwrap()` in library code (scanner, server, pricing). OK in tests and main.
- Log with `tracing`: `debug!` for per-file progress, `info!` for scan summaries, `warn!` for recoverable errors

## Common Tasks

### Adding a new model to pricing

Edit `pricing.rs` only. The pricing table is a `const` array. Add the model name and rates. Tests will verify the lookup logic.

### Adding a new JSONL field

1. Add field to the `Turn` or `Session` struct in `models.rs`
2. Parse it in `parser.rs`
3. Add column migration in `db.rs` (ALTER TABLE with try/catch pattern)
4. Expose via API in `api.rs` if needed by the dashboard
5. Update `index.html` / `app.js` if it should appear in the UI

### Changing the database schema

Always use additive migrations (ALTER TABLE ADD COLUMN). Check for column existence before adding. Never drop columns or tables in migrations -- only in full rescan.
