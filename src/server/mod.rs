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

pub async fn serve(
    host: String,
    port: u16,
    db_path: PathBuf,
    projects_dirs: Option<Vec<PathBuf>>,
    oauth_enabled: bool,
    oauth_refresh_interval: u64,
    webhook_config: WebhookConfig,
) -> anyhow::Result<()> {
    let state = Arc::new(AppState {
        db_path,
        projects_dirs,
        oauth_enabled,
        oauth_refresh_interval,
        oauth_cache: RwLock::new(None),
        db_lock: Mutex::new(()),
        webhook_state: Mutex::new(WebhookState::default()),
        webhook_config,
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

    let addr = format!("{}:{}", host, port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!("Dashboard running at http://{}", addr);
    eprintln!("Dashboard running at http://{addr}");
    eprintln!("Press Ctrl+C to stop.");
    axum::serve(listener, app).await?;
    Ok(())
}
