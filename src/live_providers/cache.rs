use std::sync::Arc;
use std::time::{Duration, Instant};

use crate::live_providers::{ALL_PROVIDERS, LIVE_PROVIDER_CACHE_SECS, ResponseScope};
use crate::models::{LiveProviderSnapshot, LiveProvidersResponse};
use crate::server::api::AppState;

pub(super) async fn cached_response(state: &Arc<AppState>) -> Option<LiveProvidersResponse> {
    let cache = state.live_provider_cache.read().await;
    match &*cache {
        Some((fetched_at, cached))
            if fetched_at.elapsed() < Duration::from_secs(LIVE_PROVIDER_CACHE_SECS) =>
        {
            Some(cached.clone())
        }
        _ => None,
    }
}

pub(super) async fn cached_response_any(state: &Arc<AppState>) -> Option<LiveProvidersResponse> {
    let cache = state.live_provider_cache.read().await;
    cache.as_ref().map(|(_, cached)| cached.clone())
}

pub(super) async fn update_cache_after_fetch(
    state: &Arc<AppState>,
    requested_provider: Option<&str>,
    scope: ResponseScope,
    response: &LiveProvidersResponse,
) {
    let mut cache = state.live_provider_cache.write().await;

    if is_full_response(response) {
        *cache = Some((Instant::now(), cacheable_response(response)));
        return;
    }

    if requested_provider.is_some()
        && scope == ResponseScope::ProviderOnly
        && let Some((fetched_at, cached)) = &mut *cache
    {
        merge_provider_snapshot(cached, response);
        *fetched_at = Instant::now();
    }
}

pub(super) fn is_full_response(response: &LiveProvidersResponse) -> bool {
    response.providers.len() == ALL_PROVIDERS.len()
        && response
            .providers
            .iter()
            .all(|snapshot| ALL_PROVIDERS.contains(&snapshot.provider.as_str()))
}

pub(super) fn cacheable_response(response: &LiveProvidersResponse) -> LiveProvidersResponse {
    let mut cached = response.clone();
    cached.requested_provider = None;
    cached.response_scope = ResponseScope::All.as_str().to_string();
    cached.cache_hit = false;
    cached.refreshed_providers.clear();
    cached
}

pub(super) fn merge_provider_snapshot(
    base: &mut LiveProvidersResponse,
    update: &LiveProvidersResponse,
) {
    for snapshot in &update.providers {
        if let Some(existing) = base
            .providers
            .iter_mut()
            .find(|candidate| candidate.provider == snapshot.provider)
        {
            *existing = snapshot.clone();
        } else {
            base.providers.push(snapshot.clone());
        }
    }
    sort_snapshots(&mut base.providers);
    base.fetched_at = chrono::Utc::now().to_rfc3339();
    base.local_notification_state = update.local_notification_state.clone();
}

pub(super) fn filter_response(
    response: &LiveProvidersResponse,
    requested_provider: Option<&str>,
    scope: ResponseScope,
    cache_hit: bool,
) -> LiveProvidersResponse {
    let providers = match (requested_provider, scope) {
        (Some(provider), ResponseScope::ProviderOnly) => response
            .providers
            .iter()
            .filter(|snapshot| snapshot.provider == provider)
            .cloned()
            .collect(),
        _ => response.providers.clone(),
    };

    LiveProvidersResponse {
        contract_version: response.contract_version,
        providers,
        fetched_at: response.fetched_at.clone(),
        requested_provider: requested_provider.map(ToOwned::to_owned),
        response_scope: scope.as_str().to_string(),
        cache_hit,
        refreshed_providers: if cache_hit {
            Vec::new()
        } else {
            response.refreshed_providers.clone()
        },
        local_notification_state: response.local_notification_state.clone(),
    }
}

pub(super) fn sort_snapshots(snapshots: &mut [LiveProviderSnapshot]) {
    snapshots.sort_by_key(|snapshot| match snapshot.provider.as_str() {
        "claude" => 0,
        "codex" => 1,
        _ => 2,
    });
}
