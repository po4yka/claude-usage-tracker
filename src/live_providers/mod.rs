use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::Result;

use crate::agent_status::models::ProviderStatus;
use crate::models::{
    LiveProviderIdentity, LiveProviderSnapshot, LiveProviderStatus, LiveProvidersResponse,
    ProviderCostSummary,
};
use crate::oauth::models::{BudgetInfo, Identity, Plan, UsageWindowsResponse, WindowInfo};
use crate::scanner::db;
use crate::server::api::{AppState, refresh_agent_status, refresh_usage_windows};

pub mod codex;

const LIVE_PROVIDER_CACHE_SECS: u64 = 60;

pub async fn load_snapshots(
    state: &Arc<AppState>,
    force_provider: Option<&str>,
) -> Result<LiveProvidersResponse> {
    if force_provider.is_none() {
        let cache = state.live_provider_cache.read().await;
        if let Some((fetched_at, cached)) = &*cache
            && fetched_at.elapsed() < Duration::from_secs(LIVE_PROVIDER_CACHE_SECS)
        {
            return Ok(cached.clone());
        }
    }

    let _refresh_guard = state.live_provider_refresh_lock.lock().await;
    if force_provider.is_none() {
        let cache = state.live_provider_cache.read().await;
        if let Some((fetched_at, cached)) = &*cache
            && fetched_at.elapsed() < Duration::from_secs(LIVE_PROVIDER_CACHE_SECS)
        {
            return Ok(cached.clone());
        }
    }

    let agent_status = refresh_agent_status(state).await.ok();
    let claude_usage = refresh_usage_windows(state).await;

    let claude = build_claude_snapshot(state, &claude_usage, agent_status.as_ref().and_then(|status| status.claude.as_ref())).await?;
    let codex = build_codex_snapshot(state, agent_status.as_ref().and_then(|status| status.openai.as_ref())).await?;
    let response = LiveProvidersResponse {
        providers: vec![claude, codex],
        fetched_at: chrono::Utc::now().to_rfc3339(),
    };

    if force_provider.is_none() {
        let mut cache = state.live_provider_cache.write().await;
        *cache = Some((Instant::now(), response.clone()));
    }

    Ok(response)
}

pub async fn load_provider_cost_summary(
    state: &Arc<AppState>,
    provider: &str,
) -> Result<ProviderCostSummary> {
    let db_path = state.db_path.clone();
    let provider = provider.to_string();
    tokio::task::spawn_blocking(move || {
        let conn = db::open_db(&db_path)?;
        db::init_db(&conn)?;
        provider_cost_summary(&conn, &provider)
    })
    .await
    .map_err(anyhow::Error::from)?
}

async fn build_claude_snapshot(
    state: &Arc<AppState>,
    usage: &UsageWindowsResponse,
    status: Option<&ProviderStatus>,
) -> Result<LiveProviderSnapshot> {
    let db_path = state.db_path.clone();
    let usage_clone = usage.clone();
    let status = status.cloned();
    tokio::task::spawn_blocking(move || {
        let conn = db::open_db(&db_path)?;
        db::init_db(&conn)?;
        let claude_usage = db::get_latest_claude_usage_response(&conn)?.latest_snapshot;
        let cost_summary = provider_cost_summary(&conn, "claude")?;

        Ok(LiveProviderSnapshot {
            provider: "claude".into(),
            available: usage_clone.available || claude_usage.is_some(),
            source_used: if usage_clone.available { "oauth".into() } else { "local".into() },
            identity: usage_clone.identity.as_ref().map(identity_to_live),
            primary: usage_clone.session.as_ref().map(window_to_live),
            secondary: usage_clone.weekly.as_ref().map(window_to_live),
            tertiary: usage_clone
                .weekly_opus
                .as_ref()
                .or(usage_clone.weekly_sonnet.as_ref())
                .map(window_to_live),
            credits: usage_clone.budget.as_ref().map(budget_to_credits),
            status: status.as_ref().map(status_to_live),
            cost_summary,
            claude_usage,
            last_refresh: chrono::Utc::now().to_rfc3339(),
            stale: !usage_clone.available,
            error: usage_clone.error.clone(),
        })
    })
    .await
    .map_err(anyhow::Error::from)?
}

async fn build_codex_snapshot(
    state: &Arc<AppState>,
    status: Option<&ProviderStatus>,
) -> Result<LiveProviderSnapshot> {
    let cost_summary = load_provider_cost_summary(state, "codex").await?;
    let mut identity = None::<LiveProviderIdentity>;
    let mut primary = None;
    let mut secondary = None;
    let mut credits = None;
    let mut source_used = "unavailable".to_string();
    let mut error = None;
    let mut available = false;

    let env = std::env::vars().collect::<Vec<_>>();
    match codex::load_auth(&env) {
        Ok(auth) => {
            identity = codex::decode_identity(&auth);
            match codex::fetch_oauth_usage(&auth).await {
                Ok(response) => {
                    available = true;
                    source_used = "oauth".into();
                    if let Some(plan_type) = response.plan_type {
                        if identity.is_none() {
                            identity = Some(LiveProviderIdentity {
                                provider: "codex".into(),
                                account_email: None,
                                account_organization: None,
                                login_method: Some("chatgpt".into()),
                                plan: Some(plan_type),
                            });
                        }
                    }
                    if let Some(rate_limit) = response.rate_limit {
                        primary = rate_limit.primary_window.as_ref().map(codex::oauth_window_to_live);
                        secondary = rate_limit
                            .secondary_window
                            .as_ref()
                            .map(codex::oauth_window_to_live);
                    }
                    credits = response.credits.as_ref().and_then(codex::oauth_credits_to_f64);
                }
                Err(fetch_error) => {
                    error = Some(fetch_error.to_string());
                }
            }
        }
        Err(load_error) => {
            error = Some(load_error.to_string());
        }
    }

    if !available {
        match codex::fetch_rpc_snapshot(Duration::from_secs(8)) {
            Ok((account, limits)) => {
                available = true;
                source_used = "cli-rpc".into();
                if identity.is_none() {
                    identity = account.and_then(|response| match response.account {
                        Some(codex::RpcAccountDetails::ChatGpt { email, plan_type }) => {
                            Some(LiveProviderIdentity {
                                provider: "codex".into(),
                                account_email: email,
                                account_organization: None,
                                login_method: Some("chatgpt".into()),
                                plan: plan_type,
                            })
                        }
                        _ => None,
                    });
                }
                primary = limits.rate_limits.primary.as_ref().map(codex::rpc_window_to_live);
                secondary = limits.rate_limits.secondary.as_ref().map(codex::rpc_window_to_live);
                credits = limits
                    .rate_limits
                    .credits
                    .as_ref()
                    .and_then(codex::rpc_credits_to_f64);
                error = None;
            }
            Err(rpc_error) => {
                if error.is_none() {
                    error = Some(rpc_error.to_string());
                }
            }
        }
    }

    if !available {
        match codex::fetch_cli_status(Duration::from_secs(8)) {
            Ok(status_snapshot) => {
                available = true;
                source_used = "cli-pty".into();
                primary = status_snapshot.primary;
                secondary = status_snapshot.secondary;
                credits = status_snapshot.credits;
                error = None;
            }
            Err(cli_error) => {
                if error.is_none() {
                    error = Some(cli_error.to_string());
                }
            }
        }
    }

    Ok(LiveProviderSnapshot {
        provider: "codex".into(),
        available,
        source_used,
        identity,
        primary,
        secondary,
        tertiary: None,
        credits,
        status: status.map(status_to_live),
        cost_summary,
        claude_usage: None,
        last_refresh: chrono::Utc::now().to_rfc3339(),
        stale: !available,
        error,
    })
}

fn window_to_live(window: &WindowInfo) -> crate::models::LiveRateWindow {
    crate::models::LiveRateWindow {
        used_percent: window.used_percent,
        resets_at: window.resets_at.clone(),
        resets_in_minutes: window.resets_in_minutes,
        window_minutes: None,
        reset_label: None,
    }
}

fn budget_to_credits(budget: &BudgetInfo) -> f64 {
    (budget.limit - budget.used).max(0.0)
}

fn identity_to_live(identity: &Identity) -> LiveProviderIdentity {
    LiveProviderIdentity {
        provider: "claude".into(),
        account_email: None,
        account_organization: None,
        login_method: identity.rate_limit_tier.clone(),
        plan: identity.plan.as_ref().map(plan_to_string),
    }
}

fn plan_to_string(plan: &Plan) -> String {
    match plan {
        Plan::Max => "max".into(),
        Plan::Pro => "pro".into(),
        Plan::Team => "team".into(),
        Plan::Enterprise => "enterprise".into(),
    }
}

fn status_to_live(status: &ProviderStatus) -> LiveProviderStatus {
    LiveProviderStatus {
        indicator: match status.indicator {
            crate::agent_status::models::StatusIndicator::None => "none",
            crate::agent_status::models::StatusIndicator::Minor => "minor",
            crate::agent_status::models::StatusIndicator::Major => "major",
            crate::agent_status::models::StatusIndicator::Critical => "critical",
            crate::agent_status::models::StatusIndicator::Maintenance => "maintenance",
            crate::agent_status::models::StatusIndicator::Unknown => "unknown",
        }
        .to_string(),
        description: status.description.clone(),
        page_url: status.page_url.clone(),
    }
}

fn provider_cost_summary(
    conn: &rusqlite::Connection,
    provider: &str,
) -> Result<ProviderCostSummary> {
    let today = chrono::Utc::now().date_naive().to_string();
    let start_date = (chrono::Utc::now().date_naive() - chrono::Duration::days(29)).to_string();
    let (today_cost_nanos, today_tokens) = db::get_provider_cost_summary_since(conn, provider, &today)?;
    let (last_30_cost_nanos, last_30_tokens) =
        db::get_provider_cost_summary_since(conn, provider, &start_date)?;
    let daily = db::get_provider_daily_cost_history_since(conn, provider, &start_date)?;

    Ok(ProviderCostSummary {
        today_tokens,
        today_cost_usd: today_cost_nanos as f64 / 1_000_000_000.0,
        last_30_days_tokens: last_30_tokens,
        last_30_days_cost_usd: last_30_cost_nanos as f64 / 1_000_000_000.0,
        daily,
    })
}
