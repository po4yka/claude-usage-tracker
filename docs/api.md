# REST API

Heimdall's axum HTTP server exposes the same data set the dashboard consumes. All endpoints bind loopback-only by default; override with `dashboard --host`.

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Dashboard HTML |
| `GET` | `/api/data` | All dashboard data (models, sessions, daily, weekly, subagent, entrypoints, service tiers, cache efficiency, version summary, project aliases applied) |
| `GET` | `/api/data?tz_offset_min=N&week_starts_on=N` | Timezone-aware bucketing for day-grouped metrics |
| `GET` | `/api/heatmap?period=<period>&tz_offset_min=N` | 7×24 cell grid + active-period averaging summary |
| `GET` | `/api/usage-windows` | Real-time rate windows, budget, identity (cached 60 s) |
| `GET` | `/api/billing-blocks` | Active billing block with burn rate, projection, token quota severity, and optional gap rows |
| `GET` | `/api/context-window` | Latest context-window fill from `live_events` (`{enabled:false}` when empty) |
| `GET` | `/api/cost-reconciliation?period=<day\|week\|month>` | Hook-reported vs locally-calculated totals with signed divergence and per-day breakdown |
| `GET` | `/api/agent-status` | Upstream provider health: Claude (status.claude.com) + OpenAI (status.openai.com). Cached; ETag conditional GET for Claude |
| `GET` | `/api/community-signal` | StatusGator-backed crowdsourced leading indicator (opt-in) |
| `POST` | `/api/rescan` | Atomic full rescan (loopback clients only) |
| `GET` | `/api/stream` | Server-Sent Events broadcasting `scan_completed` from the file-watcher |
| `GET` | `/api/mcp` | MCP HTTP transport (when `mcp serve --transport=http`, loopback-only bind) |
| `GET` | `/api/health` | Health check |

## Conventions

- Money columns are emitted as `*_estimated_cost` (USD float) plus `*_estimated_cost_nanos` (i64 nanos) so consumers can choose precision-vs-readability per call.
- Date columns are ISO-8601 in JSON/CSV regardless of the `--locale` flag.
- `/api/rescan` is gated to loopback to prevent remote forced-rescan amplification; the dashboard talks to it from the same origin.
- `/api/stream` is an SSE channel emitting `event: scan_completed\ndata: {...}\n\n` after each file-watcher debounce.

## MCP transport

`/api/mcp` is mounted only when running `claude-usage-tracker mcp serve --transport=http`. Same dataset as REST; AI-consumable schemas via the `rmcp` macros. See [features.md § MCP server](features.md#mcp-server-model-context-protocol).
