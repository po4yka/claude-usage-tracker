use std::sync::Arc;
use std::time::Instant;

use anyhow::Result;

use crate::agent_status::models::ProviderStatus;
use crate::analytics::blocks::identify_blocks;
use crate::analytics::depletion::{
    billing_block_signal, build_depletion_forecast, primary_window_signal, secondary_window_signal,
};
use crate::analytics::predictive::compute_predictive_insights;
use crate::analytics::quota::compute_quota_suggestions;
use crate::models::{
    LiveFloatPercentiles, LiveHistoricalEnvelope, LiveIntegerPercentiles, LiveLimitHitAnalysis,
    LivePredictiveBurnRate, LivePredictiveInsights, LiveProviderIdentity, LiveProviderSnapshot,
    LiveProviderSourceAttempt, LiveQuotaSuggestionLevel, LiveQuotaSuggestions, LiveRateWindow,
};
use crate::oauth::credentials;
use crate::oauth::models::{BudgetInfo, Identity, Plan, UsageWindowsResponse, WindowInfo};
use crate::scanner::db;
use crate::server::api::AppState;

pub(super) async fn build_claude_snapshot(
    state: &Arc<AppState>,
    usage: &UsageWindowsResponse,
    status: Option<&ProviderStatus>,
    session_length_hours: f64,
) -> Result<LiveProviderSnapshot> {
    let started_at = Instant::now();
    let db_path = state.db_path.clone();
    let blocks_token_limit = state.blocks_token_limit;
    let usage_clone = usage.clone();
    let status = status.cloned();
    let env = std::env::vars().collect::<Vec<_>>();
    let resolved_auth = credentials::resolve_auth(&env);
    let auth = resolved_auth.health.clone();
    let resolved_identity = resolved_auth.identity.clone();
    tokio::task::spawn_blocking(move || {
        use crate::analytics::blocks::{calculate_burn_rate, project_block_usage};
        use crate::analytics::quota::compute_quota;

        let conn = db::open_db(&db_path)?;
        db::init_db(&conn)?;
        let claude_usage = db::get_latest_claude_usage_response(&conn)?.latest_snapshot;
        let cost_summary = super::provider_cost_summary(&conn, "claude")?;
        let turns = db::load_all_turns(&conn)?;
        let blocks = identify_blocks(&turns, session_length_hours);
        let now = chrono::Utc::now();
        let active_projection = blocks
            .iter()
            .find(|block| block.is_active && !block.is_gap)
            .map(|block| {
                let projection = project_block_usage(block, calculate_burn_rate(block, now), now);
                projection.projected_tokens as i64
            });
        let quota_suggestions =
            compute_quota_suggestions(&blocks, blocks_token_limit).map(live_quota_suggestions);
        let primary = usage_clone.session.as_ref().map(window_to_live);
        let secondary = usage_clone.weekly.as_ref().map(window_to_live);
        let depletion_forecast = {
            let mut signals = Vec::new();
            if let Some(limit) = blocks_token_limit
                && let Some(active_block) =
                    blocks.iter().find(|block| block.is_active && !block.is_gap)
            {
                let projection =
                    project_block_usage(active_block, calculate_burn_rate(active_block, now), now);
                if let Some(quota) = compute_quota(active_block, &projection, limit) {
                    signals.push(billing_block_signal(
                        "Billing block",
                        quota.current_pct * 100.0,
                        Some(quota.projected_pct * 100.0),
                        Some(quota.remaining_tokens),
                        Some(100.0 - (quota.current_pct * 100.0)),
                        Some(active_block.end.to_rfc3339()),
                    ));
                }
            }
            if let Some(window) = primary.as_ref() {
                signals.push(primary_window_signal(
                    window.used_percent,
                    Some(100.0 - window.used_percent),
                    window.resets_in_minutes,
                    None,
                    window.resets_at.clone(),
                ));
            }
            if let Some(window) = secondary.as_ref() {
                signals.push(secondary_window_signal(
                    window.used_percent,
                    Some(100.0 - window.used_percent),
                    window.resets_in_minutes,
                    None,
                    window.resets_at.clone(),
                ));
            }
            build_depletion_forecast(signals)
        };
        let predictive_insights =
            compute_predictive_insights(&blocks, blocks_token_limit, active_projection, now)
                .map(live_predictive_insights);

        let mut source_attempts = Vec::new();
        let source_used = if usage_clone.available && usage_clone.source == "oauth" {
            source_attempts.push(LiveProviderSourceAttempt {
                source: "oauth".into(),
                outcome: "success".into(),
                message: None,
            });
            "oauth"
        } else if usage_clone.available && usage_clone.source == "admin" {
            source_attempts.push(LiveProviderSourceAttempt {
                source: "oauth".into(),
                outcome: "unavailable".into(),
                message: Some("OAuth usage unavailable; using Anthropic admin analytics.".into()),
            });
            source_attempts.push(LiveProviderSourceAttempt {
                source: "admin".into(),
                outcome: "success".into(),
                message: Some("using org-wide Anthropic admin analytics".into()),
            });
            "admin"
        } else if claude_usage.is_some() {
            source_attempts.push(LiveProviderSourceAttempt {
                source: "oauth".into(),
                outcome: if usage_clone.error.is_some() {
                    "error".into()
                } else {
                    "unavailable".into()
                },
                message: usage_clone.error.clone(),
            });
            source_attempts.push(LiveProviderSourceAttempt {
                source: "local".into(),
                outcome: "success".into(),
                message: Some("using latest stored /usage factors".into()),
            });
            "local"
        } else {
            source_attempts.push(LiveProviderSourceAttempt {
                source: "oauth".into(),
                outcome: if usage_clone.error.is_some() {
                    "error".into()
                } else {
                    "unavailable".into()
                },
                message: usage_clone.error.clone(),
            });
            "unavailable"
        };
        let last_attempted_source = source_attempts.last().map(|attempt| attempt.source.clone());
        let resolved_via_fallback = source_used == "local" || source_used == "admin";

        Ok(LiveProviderSnapshot {
            provider: "claude".into(),
            available: usage_clone.available || claude_usage.is_some(),
            source_used: source_used.into(),
            last_attempted_source,
            resolved_via_fallback,
            refresh_duration_ms: started_at.elapsed().as_millis() as u64,
            source_attempts,
            identity: usage_clone
                .identity
                .as_ref()
                .map(identity_to_live)
                .or_else(|| resolved_identity.as_ref().map(identity_to_live)),
            primary,
            secondary,
            tertiary: usage_clone
                .weekly_opus
                .as_ref()
                .or(usage_clone.weekly_sonnet.as_ref())
                .map(window_to_live),
            credits: usage_clone.budget.as_ref().map(budget_to_credits),
            status: status.as_ref().map(super::status_to_live),
            auth,
            cost_summary,
            claude_usage,
            claude_admin: usage_clone.admin_fallback.clone(),
            quota_suggestions,
            depletion_forecast,
            predictive_insights,
            last_refresh: chrono::Utc::now().to_rfc3339(),
            stale: false,
            error: if source_used == "unavailable" {
                usage_clone.error.clone()
            } else {
                None
            },
        })
    })
    .await
    .map_err(anyhow::Error::from)?
}

fn live_quota_suggestions(
    suggestions: crate::analytics::quota::QuotaSuggestions,
) -> LiveQuotaSuggestions {
    LiveQuotaSuggestions {
        sample_count: suggestions.sample_count,
        population_count: suggestions.population_count,
        recommended_key: suggestions.recommended_key,
        sample_strategy: suggestions.sample_strategy,
        sample_label: suggestions.sample_label,
        levels: suggestions
            .levels
            .into_iter()
            .map(|level| LiveQuotaSuggestionLevel {
                key: level.key,
                label: level.label,
                limit_tokens: level.limit_tokens,
            })
            .collect(),
        note: suggestions.note,
    }
}

fn live_predictive_insights(
    insights: crate::analytics::predictive::PredictiveInsights,
) -> LivePredictiveInsights {
    LivePredictiveInsights {
        rolling_hour_burn: insights
            .rolling_hour_burn
            .map(|burn| LivePredictiveBurnRate {
                tokens_per_min: burn.tokens_per_min,
                cost_per_hour_nanos: burn.cost_per_hour_nanos,
                coverage_minutes: burn.coverage_minutes,
                tier: burn.tier,
            }),
        historical_envelope: insights
            .historical_envelope
            .map(|envelope| LiveHistoricalEnvelope {
                sample_count: envelope.sample_count,
                tokens: live_integer_percentiles(envelope.tokens),
                cost_usd: live_float_percentiles(envelope.cost_usd),
                turns: live_integer_percentiles(envelope.turns),
            }),
        limit_hit_analysis: insights
            .limit_hit_analysis
            .map(|analysis| LiveLimitHitAnalysis {
                sample_count: analysis.sample_count,
                hit_count: analysis.hit_count,
                hit_rate: analysis.hit_rate,
                threshold_tokens: analysis.threshold_tokens,
                threshold_percent: analysis.threshold_percent,
                active_current_hit: analysis.active_current_hit,
                active_projected_hit: analysis.active_projected_hit,
                risk_level: analysis.risk_level,
                summary_label: analysis.summary_label,
            }),
    }
}

fn live_integer_percentiles(
    percentiles: crate::analytics::predictive::IntegerPercentiles,
) -> LiveIntegerPercentiles {
    LiveIntegerPercentiles {
        average: percentiles.average,
        p50: percentiles.p50,
        p75: percentiles.p75,
        p90: percentiles.p90,
        p95: percentiles.p95,
    }
}

fn live_float_percentiles(
    percentiles: crate::analytics::predictive::FloatPercentiles,
) -> LiveFloatPercentiles {
    LiveFloatPercentiles {
        average: percentiles.average,
        p50: percentiles.p50,
        p75: percentiles.p75,
        p90: percentiles.p90,
        p95: percentiles.p95,
    }
}

pub(super) fn window_to_live(window: &WindowInfo) -> LiveRateWindow {
    LiveRateWindow {
        used_percent: window.used_percent,
        resets_at: window.resets_at.clone(),
        resets_in_minutes: window.resets_in_minutes,
        window_minutes: None,
        reset_label: None,
    }
}

pub(super) fn budget_to_credits(budget: &BudgetInfo) -> f64 {
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
