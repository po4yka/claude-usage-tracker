use serde::Serialize;

#[derive(Debug, Clone, Default)]
pub struct Session {
    pub session_id: String,
    pub project_name: String,
    pub project_slug: String,
    pub first_timestamp: String,
    pub last_timestamp: String,
    pub git_branch: String,
    pub model: Option<String>,
    pub entrypoint: String,
    pub total_input_tokens: i64,
    pub total_output_tokens: i64,
    pub total_cache_read: i64,
    pub total_cache_creation: i64,
    pub turn_count: i64,
}

#[derive(Debug, Clone, Default)]
pub struct Turn {
    pub session_id: String,
    pub timestamp: String,
    pub model: String,
    pub input_tokens: i64,
    pub output_tokens: i64,
    pub cache_read_tokens: i64,
    pub cache_creation_tokens: i64,
    pub tool_name: Option<String>,
    pub cwd: String,
    pub message_id: String,
    pub service_tier: Option<String>,
    pub inference_geo: Option<String>,
    pub is_subagent: bool,
    pub agent_id: Option<String>,
    pub source_path: String,
    /// All tool names from content blocks (transient, not persisted to turns table).
    #[allow(dead_code)]
    pub all_tools: Vec<String>,
}

#[derive(Debug, Clone, Default)]
pub struct SessionMeta {
    pub session_id: String,
    pub project_name: String,
    pub project_slug: String,
    pub first_timestamp: String,
    pub last_timestamp: String,
    pub git_branch: String,
    pub model: Option<String>,
    pub entrypoint: String,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct ScanResult {
    pub new: usize,
    pub updated: usize,
    pub skipped: usize,
    pub turns: usize,
    pub sessions: usize,
}

#[derive(Debug, Clone, Serialize)]
pub struct DashboardData {
    pub all_models: Vec<String>,
    pub daily_by_model: Vec<DailyModelRow>,
    pub sessions_all: Vec<SessionRow>,
    pub subagent_summary: SubagentSummary,
    pub entrypoint_breakdown: Vec<EntrypointSummary>,
    pub service_tiers: Vec<ServiceTierSummary>,
    pub tool_summary: Vec<ToolSummary>,
    pub mcp_summary: Vec<McpServerSummary>,
    pub generated_at: String,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct SubagentSummary {
    pub parent_turns: i64,
    pub parent_input: i64,
    pub parent_output: i64,
    pub subagent_turns: i64,
    pub subagent_input: i64,
    pub subagent_output: i64,
    pub unique_agents: i64,
}

#[derive(Debug, Clone, Serialize)]
pub struct DailyModelRow {
    pub day: String,
    pub model: String,
    pub input: i64,
    pub output: i64,
    pub cache_read: i64,
    pub cache_creation: i64,
    pub turns: i64,
    pub cost: f64,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct EntrypointSummary {
    pub entrypoint: String,
    pub sessions: i64,
    pub turns: i64,
    pub input: i64,
    pub output: i64,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct ServiceTierSummary {
    pub service_tier: String,
    pub inference_geo: String,
    pub turns: i64,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct ToolSummary {
    pub tool_name: String,
    pub category: String,
    pub mcp_server: Option<String>,
    pub invocations: i64,
    pub turns_used: i64,
    pub sessions_used: i64,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct McpServerSummary {
    pub server: String,
    pub tools_used: i64,
    pub invocations: i64,
    pub sessions_used: i64,
}

#[derive(Debug, Clone, Serialize)]
pub struct SessionRow {
    pub session_id: String,
    pub project: String,
    pub last: String,
    pub last_date: String,
    pub duration_min: f64,
    pub model: String,
    pub turns: i64,
    pub input: i64,
    pub output: i64,
    pub cache_read: i64,
    pub cache_creation: i64,
    pub cost: f64,
    pub is_billable: bool,
    pub subagent_count: i64,
    pub subagent_turns: i64,
}
