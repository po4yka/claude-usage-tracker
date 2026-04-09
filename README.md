# Claude Usage Tracker

A fast, local analytics dashboard for Claude Code usage and token consumption. Built in Rust.

Reads JSONL transcripts written by Claude Code (CLI, VS Code, JetBrains, Dispatched sessions) and presents an interactive dashboard with cost estimates, charts, and filtering.

## Features

- **Incremental scanning** -- only processes new/changed JSONL files
- **Streaming deduplication** -- handles Claude Code's multiple JSONL records per API response
- **Interactive dashboard** -- dark-themed UI with charts, sortable tables, CSV export
- **Cost estimation** -- based on Anthropic API pricing with cache read/write adjustments
- **CLI reporting** -- quick terminal summaries without launching a browser
- **Cross-platform** -- macOS, Linux, Windows
- **Zero runtime dependencies** -- single binary, no Python/Node/npm required

## Installation

### From source

```bash
cargo install --path .
```

### Pre-built binaries

Download from [Releases](https://github.com/po4yka/claude-usage-tracker/releases).

## Usage

```bash
# Scan transcripts and open the dashboard
claude-usage-tracker dashboard

# Quick terminal summary of today's usage
claude-usage-tracker today

# All-time statistics
claude-usage-tracker stats

# Scan only (update database without UI)
claude-usage-tracker scan

# Custom transcript directory
claude-usage-tracker scan --projects-dir /path/to/projects
```

The dashboard runs at `http://localhost:8080` by default. Override with `--host` and `--port` flags, or `HOST`/`PORT` environment variables.

## Data Sources

Automatically discovers JSONL transcripts from:

| Platform | Path |
|----------|------|
| Claude Code CLI | `~/.claude/projects/` |
| Xcode integration | `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/projects/` |
| Custom | `--projects-dir <PATH>` |

## How It Works

1. **Scan** -- walks project directories for `*.jsonl` files
2. **Parse** -- extracts session metadata and per-turn token usage from each record
3. **Deduplicate** -- streaming events sharing the same `message.id` are collapsed (last record wins)
4. **Store** -- upserts into a local SQLite database at `~/.claude/usage.db`
5. **Serve** -- axum HTTP server delivers the dashboard UI and JSON API

## Architecture

```
claude-usage-tracker/
  src/
    main.rs          -- CLI entry point (clap)
    scanner/
      mod.rs         -- orchestrates scanning pipeline
      parser.rs      -- JSONL parsing and deduplication
      db.rs          -- SQLite schema, queries, migrations
    server/
      mod.rs         -- axum HTTP server
      api.rs         -- JSON API endpoints
      assets.rs      -- embedded static assets (HTML/CSS/JS)
    pricing.rs       -- model pricing table and cost calculation
    models.rs        -- shared data types
```

## Cost Estimation

Costs are estimated using Anthropic API pricing. Actual costs for Max/Pro subscribers differ.

| Token Type | Pricing |
|------------|---------|
| Input | Base rate per model |
| Output | Base rate per model |
| Cache read | ~10% of input rate |
| Cache creation | ~125% of input rate |

## Prior Art

Inspired by [phuryn/claude-usage](https://github.com/phuryn/claude-usage) (Python). This project is a ground-up rewrite in Rust with:

- Single-binary distribution (no Python required)
- Faster scanning for large transcript histories
- Improved UI with better charting and responsive design
- Subagent session tracking
- Extended JSONL field extraction (service tier, inference geo, ephemeral cache)

## License

MIT
