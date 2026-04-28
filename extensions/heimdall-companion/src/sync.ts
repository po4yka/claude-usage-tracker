import type { ExtensionConfig, WebConversation } from './types';
import { postConversation, postHeartbeat } from './heimdall';
import { saveConfig } from './storage';

export interface SyncResult {
  vendor: string;
  listed: number;
  written: number;
  unchanged: number;
  errors: string[];
}

/** Pure function: given current state and a list of (id, updated_at), return ids to fetch. */
export function pickChanged(
  lastSeen: Record<string, string>,
  observed: Array<{ id: string; updated_at?: string }>,
): string[] {
  const out: string[] = [];
  for (const item of observed) {
    const seen = lastSeen[item.id];
    if (!item.updated_at) {
      // No timestamp from vendor — only fetch if we've never seen this id.
      if (!seen) out.push(item.id);
      continue;
    }
    if (!seen || item.updated_at > seen) out.push(item.id);
  }
  return out;
}

/** SHA-256 hex of the sorted, newline-separated keys of a top-level object. */
export async function schemaFingerprint(value: unknown): Promise<string> {
  if (value === null || typeof value !== 'object') return '';
  const keys = Object.keys(value as Record<string, unknown>).sort().join('\n');
  const buf = new TextEncoder().encode(keys);
  const hash = await crypto.subtle.digest('SHA-256', buf);
  return [...new Uint8Array(hash)].map(b => b.toString(16).padStart(2, '0')).join('');
}

export interface VendorAdapter {
  vendor: string;
  list(): Promise<Array<{ id: string; updated_at?: string }>>;
  fetch(id: string): Promise<unknown>;
}

export async function syncVendor(
  cfg: ExtensionConfig,
  adapter: VendorAdapter,
): Promise<SyncResult> {
  const result: SyncResult = {
    vendor: adapter.vendor, listed: 0, written: 0, unchanged: 0, errors: [],
  };
  const state = cfg.vendors[adapter.vendor];
  if (!state || !state.enabled) return result;

  let observed: Array<{ id: string; updated_at?: string }> = [];
  try {
    observed = await adapter.list();
  } catch (e) {
    result.errors.push(`list: ${(e as Error).message}`);
    return result;
  }
  result.listed = observed.length;
  const changed = pickChanged(state.lastSeenUpdatedAt, observed);

  for (const id of changed) {
    try {
      const payload = await adapter.fetch(id);
      const fingerprint = await schemaFingerprint(payload);
      const conv: WebConversation = {
        vendor: adapter.vendor,
        conversation_id: id,
        captured_at: new Date().toISOString(),
        schema_fingerprint: fingerprint,
        payload,
      };
      const { saved, unchanged } = await postConversation(cfg, conv);
      if (saved) result.written++;
      if (unchanged) result.unchanged++;
      const observedItem = observed.find(o => o.id === id);
      state.lastSeenUpdatedAt[id] = observedItem?.updated_at ?? new Date().toISOString();
    } catch (e) {
      result.errors.push(`${id}: ${(e as Error).message}`);
      cfg.telemetry.totalErrors++;
    }
  }
  state.lastSyncAt = new Date().toISOString();
  cfg.telemetry.totalCaptures += result.written;

  await postHeartbeat(cfg, adapter.vendor).catch(() => {});
  await saveConfig(cfg);
  return result;
}
