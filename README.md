# Claude Usage Tracker

A fast, local analytics dashboard for Claude Code and Codex usage. Built in Rust.

Reads local transcripts written by Claude Code and Codex, then presents an interactive dashboard with cost estimates, charts, provider-aware filtering, and rate limit tracking.

## Features

### Core
- **Incremental scanning** -- only processes new/changed JSONL files
- **Multi-provider analytics** -- Claude and Codex share one SQLite database and dashboard
- **Streaming deduplication** -- handles Claude Code and Codex incremental session records
- **Interactive dashboard** -- industrial monochrome UI (dark + light themes) with ApexCharts, sortable tables, CSV export
- **Cost estimation** -- single source of truth in Rust, with volume discount support and integer-nanos precision
- **Turn-level cost snapshots** -- each turn stores estimated cost, pricing snapshot, billing mode, and confidence tier
- **CLI reporting** -- quick terminal summaries with `--json` flag for scripting
- **Cross-platform** -- macOS, Linux, Windows
- **Zero runtime dependencies** -- single binary, no Python/Node/npm required

### Real-Time Monitoring (via OAuth)
- **Rate window tracking** -- 5-hour session, 7-day weekly, and per-model (Opus/Sonnet) quotas with progress bars and reset countdowns
- **Plan detection** -- automatically identifies Max/Pro/Team/Enterprise from Claude credentials
- **Monthly budget tracking** -- spend vs limit progress bar from OAuth API
- **Session depletion alerts** -- inline `[ERROR: ...]` status next to the rate-window cards when quota runs out or restores
- **Auto token refresh** -- refreshes expired OAuth tokens automatically

### Analytics
- **Codex local log support** -- scans archived Codex session JSONL and estimates cost from OpenAI API pricing
- **Estimation confidence tiers** -- distinguishes exact pricing matches from fallback/unknown model estimates
- **OpenAI org reconciliation** -- optional Codex comparison against official OpenAI organization usage buckets
- **Subagent session linking** -- tracks parent vs subagent token usage with breakdown panel
- **Entrypoint breakdown** -- usage split by CLI, VS Code, JetBrains
- **Service tier tracking** -- inference region and service tier visibility
- **Cost trend sparkline** -- 7-day mini chart
- **Project search/filter** -- text search across projects with URL persistence
- **Paginated sessions** -- 25 per page with prev/next navigation

### Extensibility
- **Config file** -- `~/.claude/usage-tracker.toml` for all settings
- **Custom pricing overrides** -- per-model rate customization
- **Webhook notifications** -- POST to URL on session depletion or cost threshold
- **JSON API** -- all dashboard data available via REST endpoints

## Install

### Prebuilt binary (recommended)

Download the tarball for your platform from the [GitHub Releases](https://github.com/po4yka/heimdall/releases) page,
extract it, and move both binaries to `/usr/local/bin`.

**macOS (recommended): universal binary — runs natively on Apple Silicon and Intel**

```bash
# macOS universal binary (arm64 + x86_64 in one file)
VERSION=$(curl -fsSL https://api.github.com/repos/po4yka/heimdall/releases/latest | jq -r '.tag_name')
curl -fsSL "https://github.com/po4yka/heimdall/releases/download/${VERSION}/heimdall-${VERSION}-universal-apple-darwin.tar.gz" \
  | tar xz --strip-components=1 -C /usr/local/bin
```

**All platforms one-liner (requires curl, jq, tar):**

```bash
# Replace PLATFORM with your target (see table below)
PLATFORM="aarch64-apple-darwin"
VERSION=$(curl -fsSL https://api.github.com/repos/po4yka/heimdall/releases/latest | jq -r '.tag_name')
curl -fsSL "https://github.com/po4yka/heimdall/releases/download/${VERSION}/heimdall-${VERSION}-${PLATFORM}.tar.gz" \
  | tar xz --strip-components=1 -C /usr/local/bin
```

Supported platforms:

| Platform | Archive |
|----------|---------|
| macOS (universal — Apple Silicon + Intel) | `heimdall-<version>-universal-apple-darwin.tar.gz` |
| macOS (Apple Silicon only) | `heimdall-<version>-aarch64-apple-darwin.tar.gz` |
| macOS (Intel only) | `heimdall-<version>-x86_64-apple-darwin.tar.gz` |
| Linux x86\_64 | `heimdall-<version>-x86_64-unknown-linux-gnu.tar.gz` |
| Linux ARM64 | `heimdall-<version>-aarch64-unknown-linux-gnu.tar.gz` |
| Windows x86\_64 | `heimdall-<version>-x86_64-pc-windows-msvc.zip` |

Verify the download against the published checksums:

```bash
# Download and verify
curl -fsSL "https://github.com/po4yka/heimdall/releases/download/${VERSION}/SHA256SUMS.txt" | sha256sum --check --ignore-missing
```

### Homebrew (macOS)

```bash
brew tap heimdall/tap
brew install heimdall/tap/heimdall
```

_The tap repository (`heimdall/homebrew-tap`) must be created and published by the maintainer before this works. The cask formula skeleton lives at `packaging/homebrew/heimdall.rb` in this repo._

### Daemon mode (macOS only)

Run the dashboard as a persistent background service that starts automatically at login:

```bash
# Install the always-on dashboard daemon (macOS only)
claude-usage-tracker daemon install

# Check status
claude-usage-tracker daemon status

# Remove the daemon
claude-usage-tracker daemon uninstall
```

The daemon runs `claude-usage-tracker dashboard --host localhost --port 8080 --watch` under launchd with `KeepAlive: true`. Logs are written to `~/Library/Logs/heimdall/`. Linux systemd and Windows Service support is deferred to a future release.

### From source

```bash
# Install from git (requires Rust toolchain)
cargo install --git https://github.com/po4yka/heimdall

# Or build locally for development
git clone https://github.com/po4yka/heimdall
cd heimdall
cargo build --release
# Binaries appear in target/release/
sudo cp target/release/claude-usage-tracker target/release/heimdall-hook /usr/local/bin/
```

## Usage

```bash
# Scan transcripts and open the dashboard
claude-usage-tracker dashboard

# Quick terminal summary of today's usage
claude-usage-tracker today
claude-usage-tracker today --json    # machine-readable output

# All-time statistics
claude-usage-tracker stats
claude-usage-tracker stats --json

# Scan only (update database without UI)
claude-usage-tracker scan

# Custom transcript directory
claude-usage-tracker scan --projects-dir /path/to/projects

# Custom host/port
claude-usage-tracker dashboard --host 0.0.0.0 --port 9090
```

## Configuration

Create `~/.claude/usage-tracker.toml` (all fields optional):

```toml
# Custom project directories (overrides platform defaults)
projects_dirs = ["/home/user/projects"]

# Database location (default: ~/.claude/usage.db)
db_path = "/custom/path/usage.db"

# Dashboard server
host = "0.0.0.0"
port = 9090

# OAuth settings (reads ~/.claude/.credentials.json)
[oauth]
enabled = true           # default: true (auto-detects credentials)
refresh_interval = 60    # seconds between API polls

# Optional OpenAI organization usage reconciliation for Codex API-backed usage
[openai]
enabled = true                    # default: true if OPENAI_ADMIN_KEY is set
admin_key_env = "OPENAI_ADMIN_KEY"
refresh_interval = 300            # seconds between API polls
lookback_days = 30                # compare local Codex estimates vs org usage over this window

# Custom pricing overrides ($/MTok)
[pricing.my-custom-model]
input = 2.0
output = 8.0
cache_write = 2.5    # optional, defaults to input * 1.25
cache_read = 0.2     # optional, defaults to input * 0.10

# Webhook notifications
[webhooks]
url = "https://hooks.example.com/notify"
cost_threshold = 50.0      # notify when daily cost exceeds this (USD)
session_depleted = true    # notify on session depletion
```

## Data Sources

Automatically discovers JSONL transcripts from:

| Platform | Path |
|----------|------|
| Claude Code CLI | `~/.claude/projects/` |
| Xcode integration | `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/projects/` |
| Codex archived sessions | `~/.codex/archived_sessions/` |
| Codex live sessions (JSONL if present) | `~/.codex/sessions/` |
| Custom | `--projects-dir <PATH>` or config file |

## How It Works

1. **Scan** -- walks project directories for `*.jsonl` files (including `subagents/` subdirectories)
2. **Parse** -- extracts provider-aware session metadata, per-turn token usage, subagent flags, service tier, and Codex tool activity
3. **Estimate** -- computes turn-level API-equivalent cost snapshots with pricing version + confidence metadata
4. **Deduplicate** -- streaming events sharing the same `message.id` are collapsed (last record wins)
5. **Store** -- upserts into a local SQLite database at `~/.claude/usage.db`
6. **Serve** -- axum HTTP server delivers the dashboard UI and JSON API
7. **Reconcile** -- optionally compares Codex local estimates to OpenAI organization usage buckets
8. **Monitor** -- polls Claude OAuth API for real-time rate windows (optional)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Dashboard HTML |
| GET | `/api/data` | All dashboard data (models, sessions, daily, subagent summary, entrypoints, service tiers) |
| GET | `/api/usage-windows` | Real-time rate windows, budget, identity (cached 60s) |
| POST | `/api/rescan` | Atomic full rescan |
| GET | `/api/health` | Health check |

## Architecture

```
src/
  main.rs              -- CLI entry point (clap)
  config.rs            -- TOML config file loading
  models.rs            -- shared data types
  openai.rs            -- OpenAI organization usage reconciliation client
  pricing.rs           -- model pricing (single source of truth, volume discounts, nanos precision)
  webhooks.rs          -- webhook notification system
  oauth/
    mod.rs             -- OAuth orchestration (poll_usage)
    credentials.rs     -- credential reading + token refresh
    api.rs             -- Claude OAuth API client
    models.rs          -- OAuth response types
  scanner/
    mod.rs             -- scan orchestration, incremental processing
    parser.rs          -- JSONL parsing, streaming dedup, subagent detection
    db.rs              -- SQLite schema, queries, migrations, rate window history
  server/
    mod.rs             -- axum HTTP server
    api.rs             -- JSON API endpoints (data, rescan, usage-windows, health)
    assets.rs          -- embedded static assets
  ui/
    app.tsx            -- Dashboard entry (data loading, filters, render)
    app.js             -- Compiled JS (committed)
    index.html         -- Dashboard HTML shell (embeds compiled CSS + JS)
    input.css          -- Tailwind v4 entry with industrial tokens
    style.css          -- Generated CSS (committed)
    components/        -- Preact components (header, filter bar, charts, tables, status)
    lib/               -- format / csv / charts / theme / status / rescan
    state/             -- Signals store and TypeScript types
```

## Development

See [CLAUDE.md](CLAUDE.md) for build instructions, conventions, and development guide.

```bash
cargo build              # build
cargo test               # 128 tests
cargo clippy -- -D warnings # lint
```

## Prior Art

Inspired by [phuryn/claude-usage](https://github.com/phuryn/claude-usage) (Python) and [CodexBar](https://github.com/nicepkg/CodexBar) (macOS menu bar app). This project combines ideas from both into a single cross-platform Rust binary.

## License

MIT
