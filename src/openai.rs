use anyhow::{Context, Result};
use reqwest::Client;
use serde::Deserialize;

use crate::models::OpenAiReconciliation;
use crate::pricing;

const OPENAI_USAGE_URL: &str = "https://api.openai.com/v1/organization/usage/completions";

#[derive(Debug, Deserialize)]
struct UsagePage {
    data: Vec<UsageBucket>,
    has_more: bool,
    next_page: Option<String>,
}

#[derive(Debug, Deserialize)]
struct UsageBucket {
    results: Vec<UsageResult>,
}

#[derive(Debug, Deserialize)]
struct UsageResult {
    input_tokens: Option<i64>,
    output_tokens: Option<i64>,
    input_cached_tokens: Option<i64>,
    num_model_requests: Option<i64>,
    model: Option<String>,
}

pub async fn fetch_org_usage_reconciliation(
    admin_key: &str,
    lookback_days: i64,
    estimated_local_cost: f64,
) -> OpenAiReconciliation {
    match fetch_org_usage_reconciliation_inner(admin_key, lookback_days, estimated_local_cost).await
    {
        Ok(data) => data,
        Err(error) => {
            let end = chrono::Utc::now().date_naive();
            let start = end - chrono::Duration::days(lookback_days.saturating_sub(1));
            OpenAiReconciliation {
                available: false,
                lookback_days,
                start_date: start.to_string(),
                end_date: end.to_string(),
                estimated_local_cost,
                api_usage_cost: 0.0,
                api_input_tokens: 0,
                api_output_tokens: 0,
                api_cached_input_tokens: 0,
                api_requests: 0,
                delta_cost: 0.0,
                error: Some(error.to_string()),
            }
        }
    }
}

async fn fetch_org_usage_reconciliation_inner(
    admin_key: &str,
    lookback_days: i64,
    estimated_local_cost: f64,
) -> Result<OpenAiReconciliation> {
    let client = Client::builder()
        .user_agent("claude-usage-tracker/0.1")
        .build()
        .context("failed to build OpenAI client")?;

    let end = chrono::Utc::now().date_naive();
    let start = end - chrono::Duration::days(lookback_days.saturating_sub(1));
    let start_time = start
        .and_hms_opt(0, 0, 0)
        .context("invalid OpenAI reconciliation start time")?
        .and_utc()
        .timestamp();
    let end_time = (end + chrono::Duration::days(1))
        .and_hms_opt(0, 0, 0)
        .context("invalid OpenAI reconciliation end time")?
        .and_utc()
        .timestamp();

    let mut page: Option<String> = None;
    let mut input_tokens = 0_i64;
    let mut output_tokens = 0_i64;
    let mut cached_input_tokens = 0_i64;
    let mut api_requests = 0_i64;
    let mut api_usage_cost = 0.0_f64;

    loop {
        let mut request = client.get(OPENAI_USAGE_URL).bearer_auth(admin_key).query(&[
            ("start_time", start_time.to_string()),
            ("end_time", end_time.to_string()),
            ("bucket_width", "1d".to_string()),
            ("limit", (lookback_days + 1).max(1).to_string()),
            ("group_by[]", "model".to_string()),
        ]);

        if let Some(page_cursor) = page.as_deref() {
            request = request.query(&[("page", page_cursor)]);
        }

        let response = request
            .send()
            .await
            .context("failed to fetch OpenAI organization usage")?
            .error_for_status()
            .context("OpenAI organization usage request failed")?;
        let payload: UsagePage = response
            .json()
            .await
            .context("failed to decode OpenAI organization usage response")?;

        for bucket in payload.data {
            for result in bucket.results {
                let Some(model) = result.model.as_deref() else {
                    continue;
                };
                if !is_codex_usage_model(model) {
                    continue;
                }

                let input = result.input_tokens.unwrap_or(0);
                let output = result.output_tokens.unwrap_or(0);
                let cached = result.input_cached_tokens.unwrap_or(0);
                input_tokens += input;
                output_tokens += output;
                cached_input_tokens += cached;
                api_requests += result.num_model_requests.unwrap_or(0);
                api_usage_cost += pricing::calc_cost(model, input, output, cached, 0);
            }
        }

        if !payload.has_more {
            break;
        }
        page = payload.next_page;
        if page.is_none() {
            break;
        }
    }

    Ok(OpenAiReconciliation {
        available: true,
        lookback_days,
        start_date: start.to_string(),
        end_date: end.to_string(),
        estimated_local_cost,
        api_usage_cost,
        api_input_tokens: input_tokens,
        api_output_tokens: output_tokens,
        api_cached_input_tokens: cached_input_tokens,
        api_requests,
        delta_cost: api_usage_cost - estimated_local_cost,
        error: None,
    })
}

fn is_codex_usage_model(model: &str) -> bool {
    let lower = model.to_ascii_lowercase();
    lower.contains("codex") || lower.starts_with("gpt-5.4") || lower.starts_with("gpt-5.3-codex")
}
