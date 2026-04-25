# CLI reference

`claude-usage-tracker` is the primary CLI; `heimdall-hook` is a tiny stdin-driven companion. Most subcommands accept a shared `--jq=<filter>`, `--locale=<BCP-47>`, `--compact`, and `--project-alias=KEY=VAL` (repeatable). `--jq` implies `--json` and runs through an embedded `jaq-core` engine — no system `jq` needed.

## Subcommand catalogue

- `scan`, `today`, `stats`, `dashboard`, `dashboard --watch`, `dashboard --no-open`, `dashboard --background-poll`
- `weekly [--start-of-week=<monday|sunday|...>] [--breakdown] [--json]`
- `blocks [--session-length=<hours>] [--token-limit=<N|max>] [--provider=<name>] [--active] [--no-gaps] [--compact] [--json]`
- `statusline [--refresh-interval=30] [--cost-source=<auto|local|hook|both>] [--visual-burn-rate=<off|bracket|emoji|both>] [--offline]`
- `mcp <serve|install|uninstall|status> [--transport=<stdio|http>] [--client=<claude-code|claude-desktop|cursor>]`
- `config <schema|show> [--format=<toml|json>]`
- `export --format=<csv|json|jsonl> --period=<today|week|month|year|all> --output=<path>` (optional `--provider`, `--project`, `--jq`)
- `optimize --format=<text|json>`
- `scheduler install|uninstall|status [--interval=<hourly|daily>]` (platform-native via launchd / cron / schtasks)
- `daemon install|uninstall|status` (macOS-only login-start dashboard via launchd with `KeepAlive: true`)
- `hook install|uninstall|status` (wires `heimdall-hook` into `~/.claude/settings.json` PreToolUse)
- `db reset [--yes]` (TTY-guarded destructive wipe — type `rebuild` interactively, or pass `--yes` in non-TTY)
- `menubar` (SwiftBar-formatted output for macOS menu-bar widgets)
- `pricing refresh` (fetch LiteLLM catalogue into `~/.cache/heimdall/litellm_pricing.json`)

## Common usage

```bash
# Scan transcripts and open the dashboard
claude-usage-tracker dashboard

# Dashboard with live auto-refresh (file-watcher + SSE)
claude-usage-tracker dashboard --watch

# Quick terminal summary of today's usage
claude-usage-tracker today
claude-usage-tracker today --json
claude-usage-tracker today --breakdown          # per-model sub-rows under provider totals
claude-usage-tracker today --compact            # narrow layout for screenshots

# All-time statistics
claude-usage-tracker stats
claude-usage-tracker stats --json

# Weekly aggregation
claude-usage-tracker weekly
claude-usage-tracker weekly --start-of-week=monday --breakdown

# 5-hour billing blocks with burn rate
claude-usage-tracker blocks                      # all blocks, most recent last
claude-usage-tracker blocks --active             # only the currently-active block
claude-usage-tracker blocks --token-limit=1M     # show REMAINING/PROJECTED quota rows
claude-usage-tracker blocks --provider=codex     # use Codex's configured session length

# Claude Code status line (reads hook JSON on stdin)
echo '{"session_id":"...","transcript_path":"...","model":"claude-sonnet-4-6"}' \
  | claude-usage-tracker statusline
claude-usage-tracker statusline --cost-source=both --visual-burn-rate=bracket

# Scan only (update database without UI)
claude-usage-tracker scan

# Custom transcript directory
claude-usage-tracker scan --projects-dir /path/to/projects

# Custom host/port
claude-usage-tracker dashboard --host 0.0.0.0 --port 9090

# Export aggregated usage
claude-usage-tracker export --format=csv --period=month --output=usage.csv
claude-usage-tracker export --format=json --period=all --output=all.json --provider=claude

# Run the waste detector
claude-usage-tracker optimize               # human-readable text
claude-usage-tracker optimize --format=json

# MCP server
claude-usage-tracker mcp serve              # stdio
claude-usage-tracker mcp serve --transport=http --port=8081   # loopback-only

# Config introspection
claude-usage-tracker config schema > schemas/heimdall.config.schema.json
claude-usage-tracker config show --format=json

# Refresh long-tail model pricing
claude-usage-tracker pricing refresh

# SwiftBar menu-bar widget (macOS)
claude-usage-tracker menubar
```

## Filter output with `--jq`

Every report command accepts `--jq <filter>` for in-tool post-processing (implies `--json`). No system `jq` needed.

```bash
claude-usage-tracker today --jq '.total_estimated_cost'
claude-usage-tracker stats --jq '.by_model[] | select(.provider == "claude") | .model'
claude-usage-tracker weekly --jq '.weeks | length'
claude-usage-tracker blocks --jq '.[0].estimated_cost'
claude-usage-tracker optimize --jq '.grade'
claude-usage-tracker export --format=jsonl --jq '.model' --output=-
```

Filter errors exit with status 2. Empty results (no match) produce no output and exit 0. `null` outputs print as the literal `null`.
