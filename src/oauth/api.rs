use std::time::Duration;

use tracing::warn;

use super::models::{BudgetInfo, Identity, OAuthUsageResponse, UsageWindowsResponse, WindowInfo};

const USAGE_ENDPOINT: &str = "https://api.anthropic.com/api/oauth/usage";
const BETA_HEADER: &str = "oauth-2025-04-20";
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

/// Fetch usage windows from the Claude OAuth API.
pub async fn fetch_usage(access_token: &str) -> UsageWindowsResponse {
    match fetch_usage_inner(access_token).await {
        Ok(resp) => resp,
        Err(e) => {
            warn!("OAuth usage fetch failed: {}", e);
            UsageWindowsResponse::with_error(e.to_string())
        }
    }
}

async fn fetch_usage_inner(access_token: &str) -> anyhow::Result<UsageWindowsResponse> {
    let client = reqwest::Client::builder()
        .timeout(REQUEST_TIMEOUT)
        .build()?;

    let resp = client
        .get(USAGE_ENDPOINT)
        .header("Authorization", format!("Bearer {}", access_token))
        .header("Accept", "application/json")
        .header("anthropic-beta", BETA_HEADER)
        .send()
        .await?;

    let status = resp.status();
    if status == reqwest::StatusCode::UNAUTHORIZED {
        return Ok(UsageWindowsResponse::with_error(
            "OAuth token expired. Run `claude login` to refresh.".into(),
        ));
    }
    if !status.is_success() {
        let body = resp.text().await.unwrap_or_default();
        return Ok(UsageWindowsResponse::with_error(format!(
            "API returned HTTP {}: {}",
            status,
            body.chars().take(200).collect::<String>()
        )));
    }

    let data: OAuthUsageResponse = resp.json().await?;
    Ok(build_response(data))
}

fn build_response(data: OAuthUsageResponse) -> UsageWindowsResponse {
    UsageWindowsResponse {
        available: true,
        session: data.five_hour.as_ref().map(WindowInfo::from_usage_window),
        weekly: data.seven_day.as_ref().map(WindowInfo::from_usage_window),
        weekly_opus: data
            .seven_day_opus
            .as_ref()
            .map(WindowInfo::from_usage_window),
        weekly_sonnet: data
            .seven_day_sonnet
            .as_ref()
            .map(WindowInfo::from_usage_window),
        budget: data
            .extra_usage
            .as_ref()
            .and_then(BudgetInfo::from_extra_usage),
        identity: None, // filled in by the caller from credentials
        error: None,
    }
}

/// Build a complete response by combining API data with identity from credentials.
pub fn with_identity(mut resp: UsageWindowsResponse, identity: Identity) -> UsageWindowsResponse {
    resp.identity = Some(identity);
    resp
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::oauth::models::{ExtraUsage, UsageWindow};

    #[test]
    fn test_build_response_full() {
        let data = OAuthUsageResponse {
            five_hour: Some(UsageWindow {
                utilization: Some(0.45),
                resets_at: Some("2099-01-01T00:00:00Z".into()),
            }),
            seven_day: Some(UsageWindow {
                utilization: Some(0.6),
                resets_at: Some("2099-01-08T00:00:00Z".into()),
            }),
            seven_day_oauth_apps: None,
            seven_day_opus: Some(UsageWindow {
                utilization: Some(0.3),
                resets_at: None,
            }),
            seven_day_sonnet: None,
            iguana_necktie: None,
            extra_usage: Some(ExtraUsage {
                is_enabled: Some(true),
                monthly_limit: Some(100.0),
                used_credits: Some(45.5),
                utilization: Some(0.455),
                currency: Some("USD".into()),
            }),
        };

        let resp = build_response(data);
        assert!(resp.available);
        assert!((resp.session.as_ref().unwrap().used_percent - 45.0).abs() < 0.01);
        assert!((resp.weekly.as_ref().unwrap().used_percent - 60.0).abs() < 0.01);
        assert!(resp.weekly_opus.is_some());
        assert!(resp.weekly_sonnet.is_none());
        assert!((resp.budget.as_ref().unwrap().used - 45.5).abs() < 0.01);
    }

    #[test]
    fn test_build_response_empty() {
        let data = OAuthUsageResponse {
            five_hour: None,
            seven_day: None,
            seven_day_oauth_apps: None,
            seven_day_opus: None,
            seven_day_sonnet: None,
            iguana_necktie: None,
            extra_usage: None,
        };

        let resp = build_response(data);
        assert!(resp.available);
        assert!(resp.session.is_none());
        assert!(resp.weekly.is_none());
        assert!(resp.budget.is_none());
    }
}
