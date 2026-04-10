use serde::Serialize;
use tracing::{debug, error, info};

use crate::config::WebhookConfig;

/// A webhook event payload sent to the configured URL.
#[allow(dead_code)]
#[derive(Debug, Serialize)]
pub struct WebhookEvent {
    pub event_type: String,
    pub message: String,
    pub details: serde_json::Value,
    pub timestamp: String,
}

#[derive(Debug, Default)]
pub struct WebhookState {
    pub session_depleted: Option<bool>,
    pub last_cost_threshold_day: Option<String>,
}

/// POST a webhook event to the given URL. Fire-and-forget via `tokio::spawn`.
#[allow(dead_code)]
pub fn send_webhook(url: &str, event: &WebhookEvent) {
    let url = url.to_owned();
    let body = match serde_json::to_string(event) {
        Ok(b) => b,
        Err(e) => {
            error!("Failed to serialize webhook event: {}", e);
            return;
        }
    };

    tokio::spawn(async move {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .build();

        let client = match client {
            Ok(c) => c,
            Err(e) => {
                error!("Failed to build HTTP client for webhook: {}", e);
                return;
            }
        };

        match client
            .post(&url)
            .header("Content-Type", "application/json")
            .body(body)
            .send()
            .await
        {
            Ok(resp) => {
                let status = resp.status();
                if status.is_success() {
                    info!("Webhook sent successfully to {}", url);
                } else {
                    error!("Webhook to {} returned status {}", url, status);
                }
            }
            Err(e) => {
                error!("Failed to send webhook to {}: {}", url, e);
            }
        }
    });
}

/// Check if webhooks are configured and the event type is enabled, then send.
#[allow(dead_code)]
pub fn notify_if_configured(config: &WebhookConfig, event: WebhookEvent) {
    let url = match &config.url {
        Some(u) => u,
        None => {
            debug!("Webhook URL not configured, skipping notification");
            return;
        }
    };

    if !url.starts_with("https://") && !url.starts_with("http://") {
        tracing::warn!("Webhook URL must use http(s) scheme: {}", url);
        return;
    }

    let enabled = match event.event_type.as_str() {
        "session_depleted" | "session_restored" => config.session_depleted,
        "cost_threshold" => config.cost_threshold.is_some(),
        _ => {
            debug!("Unknown webhook event type: {}", event.event_type);
            false
        }
    };

    if !enabled {
        debug!(
            "Webhook event type '{}' is not enabled, skipping",
            event.event_type
        );
        return;
    }

    send_webhook(url, &event);
}

pub fn session_transition_event(
    config: &WebhookConfig,
    state: &mut WebhookState,
    used_percent: f64,
    resets_in_minutes: Option<i64>,
) -> Option<WebhookEvent> {
    if !config.session_depleted {
        state.session_depleted = Some(used_percent >= 99.99);
        return None;
    }

    let is_depleted = used_percent >= 99.99;
    let previous = state.session_depleted.replace(is_depleted);

    match previous {
        Some(prev) if prev == is_depleted => None,
        Some(false) if is_depleted => Some(WebhookEvent {
            event_type: "session_depleted".to_string(),
            message: match resets_in_minutes {
                Some(minutes) => format!("Claude session depleted. Resets in {} minutes.", minutes),
                None => "Claude session depleted.".to_string(),
            },
            details: serde_json::json!({
                "used_percent": used_percent,
                "resets_in_minutes": resets_in_minutes,
            }),
            timestamp: chrono::Utc::now().to_rfc3339(),
        }),
        Some(true) if !is_depleted => Some(WebhookEvent {
            event_type: "session_restored".to_string(),
            message: "Claude session restored.".to_string(),
            details: serde_json::json!({
                "used_percent": used_percent,
                "resets_in_minutes": resets_in_minutes,
            }),
            timestamp: chrono::Utc::now().to_rfc3339(),
        }),
        _ => None,
    }
}

pub fn cost_threshold_event(
    config: &WebhookConfig,
    state: &mut WebhookState,
    day: &str,
    daily_cost: f64,
) -> Option<WebhookEvent> {
    let threshold = config.cost_threshold?;
    if daily_cost <= threshold {
        return None;
    }
    if state.last_cost_threshold_day.as_deref() == Some(day) {
        return None;
    }

    state.last_cost_threshold_day = Some(day.to_string());
    Some(WebhookEvent {
        event_type: "cost_threshold".to_string(),
        message: format!("Daily cost exceeded ${threshold:.2} on {day}."),
        details: serde_json::json!({
            "day": day,
            "daily_cost": daily_cost,
            "threshold": threshold,
        }),
        timestamp: chrono::Utc::now().to_rfc3339(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_webhook_event_serialization() {
        let event = WebhookEvent {
            event_type: "cost_threshold".to_string(),
            message: "Daily cost exceeded $50.00".to_string(),
            details: json!({"daily_cost": 52.30, "threshold": 50.0}),
            timestamp: "2026-04-09T12:00:00Z".to_string(),
        };

        let serialized = serde_json::to_string(&event).expect("should serialize");
        let deserialized: serde_json::Value =
            serde_json::from_str(&serialized).expect("should be valid JSON");

        assert_eq!(deserialized["event_type"], "cost_threshold");
        assert_eq!(deserialized["message"], "Daily cost exceeded $50.00");
        assert_eq!(deserialized["details"]["daily_cost"], 52.30);
        assert_eq!(deserialized["timestamp"], "2026-04-09T12:00:00Z");
    }

    #[test]
    fn test_notify_no_url_configured() {
        let config = WebhookConfig {
            url: None,
            cost_threshold: Some(50.0),
            session_depleted: true,
        };

        let event = WebhookEvent {
            event_type: "cost_threshold".to_string(),
            message: "test".to_string(),
            details: json!({}),
            timestamp: "2026-04-09T12:00:00Z".to_string(),
        };

        // Should not panic when no URL is configured
        notify_if_configured(&config, event);
    }

    #[test]
    fn test_notify_event_type_disabled() {
        let config = WebhookConfig {
            url: Some("https://example.com/hook".to_string()),
            cost_threshold: Some(50.0),
            session_depleted: false, // session events disabled
        };

        let event = WebhookEvent {
            event_type: "session_depleted".to_string(),
            message: "test".to_string(),
            details: json!({}),
            timestamp: "2026-04-09T12:00:00Z".to_string(),
        };

        // Should not send (session_depleted is false) and should not panic
        notify_if_configured(&config, event);
    }

    #[test]
    fn test_notify_cost_threshold_disabled() {
        let config = WebhookConfig {
            url: Some("https://example.com/hook".to_string()),
            cost_threshold: None, // cost threshold not set
            session_depleted: true,
        };

        let event = WebhookEvent {
            event_type: "cost_threshold".to_string(),
            message: "test".to_string(),
            details: json!({}),
            timestamp: "2026-04-09T12:00:00Z".to_string(),
        };

        // Should not send (cost_threshold is None) and should not panic
        notify_if_configured(&config, event);
    }

    #[test]
    fn test_notify_unknown_event_type() {
        let config = WebhookConfig {
            url: Some("https://example.com/hook".to_string()),
            cost_threshold: Some(50.0),
            session_depleted: true,
        };

        let event = WebhookEvent {
            event_type: "unknown_event".to_string(),
            message: "test".to_string(),
            details: json!({}),
            timestamp: "2026-04-09T12:00:00Z".to_string(),
        };

        // Should not panic for unknown event types
        notify_if_configured(&config, event);
    }

    #[test]
    fn test_session_transition_event_depleted_then_restored() {
        let config = WebhookConfig {
            url: Some("https://example.com/hook".to_string()),
            cost_threshold: None,
            session_depleted: true,
        };
        let mut state = WebhookState::default();

        assert!(session_transition_event(&config, &mut state, 50.0, Some(60)).is_none());

        let depleted = session_transition_event(&config, &mut state, 100.0, Some(30))
            .expect("depletion event");
        assert_eq!(depleted.event_type, "session_depleted");

        let restored =
            session_transition_event(&config, &mut state, 25.0, Some(120)).expect("restored event");
        assert_eq!(restored.event_type, "session_restored");
    }

    #[test]
    fn test_cost_threshold_event_only_once_per_day() {
        let config = WebhookConfig {
            url: Some("https://example.com/hook".to_string()),
            cost_threshold: Some(50.0),
            session_depleted: false,
        };
        let mut state = WebhookState::default();

        let first =
            cost_threshold_event(&config, &mut state, "2026-04-10", 60.0).expect("threshold event");
        assert_eq!(first.event_type, "cost_threshold");
        assert!(cost_threshold_event(&config, &mut state, "2026-04-10", 70.0).is_none());
        assert!(cost_threshold_event(&config, &mut state, "2026-04-11", 70.0).is_some());
    }
}
