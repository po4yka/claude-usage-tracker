pub mod api;
pub mod assets;
#[cfg(test)]
mod tests;

use std::path::PathBuf;
use std::sync::Arc;

use axum::Router;
use axum::response::Html;
use axum::routing::{get, post};
use tokio::sync::{Mutex, RwLock};

use crate::config::WebhookConfig;
use crate::webhooks::WebhookState;
use api::AppState;

pub struct ServeOptions {
    pub host: String,
    pub port: u16,
    pub db_path: PathBuf,
    pub projects_dirs: Option<Vec<PathBuf>>,
    pub oauth_enabled: bool,
    pub oauth_refresh_interval: u64,
    pub openai_enabled: bool,
    pub openai_admin_key_env: String,
    pub openai_refresh_interval: u64,
    pub openai_lookback_days: i64,
    pub webhook_config: WebhookConfig,
}

pub async fn serve(options: ServeOptions) -> anyhow::Result<()> {
    let state = Arc::new(AppState {
        db_path: options.db_path,
        projects_dirs: options.projects_dirs,
        oauth_enabled: options.oauth_enabled,
        oauth_refresh_interval: options.oauth_refresh_interval,
        oauth_cache: RwLock::new(None),
        openai_enabled: options.openai_enabled,
        openai_admin_key_env: options.openai_admin_key_env,
        openai_refresh_interval: options.openai_refresh_interval,
        openai_lookback_days: options.openai_lookback_days,
        openai_cache: RwLock::new(None),
        db_lock: Mutex::new(()),
        webhook_state: Mutex::new(WebhookState::default()),
        webhook_config: options.webhook_config,
    });
    let dashboard_html = assets::render_dashboard();

    let app = Router::new()
        .route(
            "/",
            get({
                let html = dashboard_html.clone();
                move || async { Html(html) }
            }),
        )
        .route(
            "/index.html",
            get({
                let html = dashboard_html;
                move || async { Html(html) }
            }),
        )
        .route("/api/data", get(api::api_data))
        .route("/api/rescan", post(api::api_rescan))
        .route("/api/usage-windows", get(api::api_usage_windows))
        .route("/api/health", get(api::api_health))
        .with_state(state);

    let addr = format!("{}:{}", options.host, options.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!("Dashboard running at http://{}", addr);
    eprintln!("Dashboard running at http://{addr}");
    eprintln!("Press Ctrl+C to stop.");
    axum::serve(listener, app).await?;
    Ok(())
}
