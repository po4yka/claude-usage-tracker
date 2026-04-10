use std::path::PathBuf;
use std::sync::Arc;
use std::time::Instant;

use axum::extract::State;
use axum::http::StatusCode;
use axum::response::Json;
use serde_json::Value;
use tokio::sync::{Mutex, RwLock};

use crate::config::WebhookConfig;
use crate::oauth;
use crate::oauth::models::UsageWindowsResponse;
use crate::scanner;
use crate::scanner::db;
use crate::webhooks::{self, WebhookState};

pub struct AppState {
    pub db_path: PathBuf,
    pub projects_dirs: Option<Vec<PathBuf>>,
    pub oauth_enabled: bool,
    pub oauth_refresh_interval: u64,
    pub oauth_cache: RwLock<Option<(Instant, UsageWindowsResponse)>>,
    pub db_lock: Mutex<()>,
    pub webhook_state: Mutex<WebhookState>,
    pub webhook_config: WebhookConfig,
}

pub async fn api_data(State(state): State<Arc<AppState>>) -> Result<Json<Value>, StatusCode> {
    let _db_guard = state.db_lock.lock().await;
    let db_path = state.db_path.clone();
    let result = tokio::task::spawn_blocking(move || -> anyhow::Result<_> {
        let conn = db::open_db(&db_path)?;
        db::init_db(&conn)?;
        db::get_dashboard_data(&conn)
    })
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    maybe_send_cost_threshold_webhook(&state, &result).await;

    let value = serde_json::to_value(result).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(value))
}

pub async fn api_rescan(State(state): State<Arc<AppState>>) -> Result<Json<Value>, StatusCode> {
    let _db_guard = state.db_lock.lock().await;
    let db_path = state.db_path.clone();
    let projects_dirs = state.projects_dirs.clone();

    let result = tokio::task::spawn_blocking(move || -> anyhow::Result<_> {
        // Atomic rescan: write to temp, then rename
        let temp_path = db_path.with_extension("db.tmp");
        cleanup_sqlite_files(&temp_path)?;
        let scan_result = scanner::scan(projects_dirs, &temp_path, false)?;
        if temp_path.exists() {
            replace_sqlite_files(&temp_path, &db_path)?;
        }
        Ok(scan_result)
    })
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let value = serde_json::to_value(result).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(value))
}

pub async fn api_usage_windows(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Value>, StatusCode> {
    if !state.oauth_enabled {
        let value = serde_json::to_value(UsageWindowsResponse::unavailable())
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        return Ok(Json(value));
    }

    // Check cache
    {
        let cache = state.oauth_cache.read().await;
        if let Some((fetched_at, ref data)) = *cache
            && fetched_at.elapsed().as_secs() < state.oauth_refresh_interval
        {
            let value =
                serde_json::to_value(data).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            return Ok(Json(value));
        }
    }

    // Cache miss or expired: fetch fresh data
    let resp = oauth::poll_usage().await;

    if let Some(session) = resp.session.as_ref() {
        maybe_send_session_webhook(&state, session.used_percent, session.resets_in_minutes).await;
    }

    // Update cache
    {
        let mut cache = state.oauth_cache.write().await;
        *cache = Some((Instant::now(), resp.clone()));
    }

    let value = serde_json::to_value(resp).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(value))
}

pub async fn api_health() -> &'static str {
    "ok"
}

fn sqlite_sidecar_paths(path: &std::path::Path) -> [PathBuf; 2] {
    [
        PathBuf::from(format!("{}-wal", path.to_string_lossy())),
        PathBuf::from(format!("{}-shm", path.to_string_lossy())),
    ]
}

fn cleanup_sqlite_files(path: &std::path::Path) -> std::io::Result<()> {
    for candidate in std::iter::once(path.to_path_buf()).chain(sqlite_sidecar_paths(path)) {
        match std::fs::remove_file(&candidate) {
            Ok(()) => {}
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => {}
            Err(err) => return Err(err),
        }
    }
    Ok(())
}

fn replace_sqlite_files(temp_path: &std::path::Path, db_path: &std::path::Path) -> std::io::Result<()> {
    cleanup_sqlite_files(db_path)?;
    std::fs::rename(temp_path, db_path)?;

    for (src, dst) in sqlite_sidecar_paths(temp_path)
        .into_iter()
        .zip(sqlite_sidecar_paths(db_path))
    {
        if src.exists() {
            std::fs::rename(src, dst)?;
        }
    }
    Ok(())
}

async fn maybe_send_session_webhook(
    state: &Arc<AppState>,
    used_percent: f64,
    resets_in_minutes: Option<i64>,
) {
    let mut webhook_state = state.webhook_state.lock().await;
    if let Some(event) = webhooks::session_transition_event(
        &state.webhook_config,
        &mut webhook_state,
        used_percent,
        resets_in_minutes,
    ) {
        webhooks::notify_if_configured(&state.webhook_config, event);
    }
}

async fn maybe_send_cost_threshold_webhook(
    state: &Arc<AppState>,
    data: &crate::models::DashboardData,
) {
    let today = chrono::Local::now().format("%Y-%m-%d").to_string();
    let daily_cost: f64 = data
        .daily_by_model
        .iter()
        .filter(|row| row.day == today)
        .map(|row| row.cost)
        .sum();

    let mut webhook_state = state.webhook_state.lock().await;
    if let Some(event) = webhooks::cost_threshold_event(
        &state.webhook_config,
        &mut webhook_state,
        &today,
        daily_cost,
    ) {
        webhooks::notify_if_configured(&state.webhook_config, event);
    }
}
