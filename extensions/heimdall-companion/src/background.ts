import { loadConfig, saveConfig } from './storage';
import { syncVendor, type VendorAdapter } from './sync';

const ALARM_NAME = 'heimdall-sync';

chrome.runtime.onInstalled.addListener(async () => {
  const cfg = await loadConfig();
  await scheduleAlarm(cfg.syncIntervalMinutes);
});

chrome.runtime.onStartup.addListener(async () => {
  const cfg = await loadConfig();
  await scheduleAlarm(cfg.syncIntervalMinutes);
});

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name !== ALARM_NAME) return;
  await runSyncAll();
});

chrome.runtime.onMessage.addListener((msg, _sender, send) => {
  if (msg?.type === 'syncNow') {
    runSyncAll().then(send).catch(err => send({ error: String(err) }));
    return true;
  }
  return false;
});

async function scheduleAlarm(minutes: number): Promise<void> {
  const period = Math.max(15, minutes); // chrome.alarms minimum 1 min, we keep 15
  await chrome.alarms.clear(ALARM_NAME);
  chrome.alarms.create(ALARM_NAME, { periodInMinutes: period });
}

async function runSyncAll(): Promise<{ results: unknown[] }> {
  const cfg = await loadConfig();
  const results: unknown[] = [];
  for (const vendor of Object.keys(cfg.vendors)) {
    const adapter = await adapterFor(vendor);
    if (!adapter) continue;
    const r = await syncVendor(cfg, adapter);
    results.push(r);
  }
  await saveConfig(cfg);
  return { results };
}

async function adapterFor(vendor: string): Promise<VendorAdapter | null> {
  // Find a tab on the vendor's origin and run the fetcher there.
  const origin = vendorOrigin(vendor);
  if (!origin) return null;
  const tabs = await chrome.tabs.query({ url: `${origin}/*` });
  const tab = tabs[0];
  if (!tab?.id) return null;
  const tabId = tab.id;
  return {
    vendor,
    async list() {
      const results = await chrome.scripting.executeScript({
        target: { tabId },
        func: vendor === 'claude.ai' ? listClaude : listChatgpt,
      });
      const first = results[0];
      return (first?.result as Array<{ id: string; updated_at?: string }> | undefined) ?? [];
    },
    async fetch(id: string) {
      const results = await chrome.scripting.executeScript({
        target: { tabId },
        func: vendor === 'claude.ai' ? fetchClaudeConv : fetchChatgptConv,
        args: [id],
      });
      const first = results[0];
      return first?.result;
    },
  };
}

function vendorOrigin(vendor: string): string | null {
  if (vendor === 'claude.ai') return 'https://claude.ai';
  if (vendor === 'chatgpt.com') return 'https://chatgpt.com';
  return null;
}

// In-page functions — must be self-contained (no imports), since
// chrome.scripting.executeScript serializes the function source.

function listClaude(): Promise<Array<{ id: string; updated_at?: string }>> {
  return (async () => {
    const orgs = await fetch('/api/organizations', { credentials: 'include' }).then(r => r.json()) as Array<{ uuid: string }>;
    const out: Array<{ id: string; updated_at?: string }> = [];
    for (const o of orgs) {
      const convs = await fetch(`/api/organizations/${o.uuid}/chat_conversations`, { credentials: 'include' }).then(r => r.json()) as Array<{ uuid: string; updated_at?: string }>;
      for (const c of convs) {
        out.push({ id: `${o.uuid}/${c.uuid}`, updated_at: c.updated_at });
      }
    }
    return out;
  })();
}

function fetchClaudeConv(combinedId: string): Promise<unknown> {
  return (async () => {
    const [orgId, convId] = combinedId.split('/', 2) as [string, string];
    const r = await fetch(`/api/organizations/${orgId}/chat_conversations/${convId}`, { credentials: 'include' });
    return r.json();
  })();
}

function listChatgpt(): Promise<Array<{ id: string; updated_at?: string }>> {
  return (async () => {
    const session = await fetch('/api/auth/session', { credentials: 'include' }).then(r => r.json()) as { accessToken?: string };
    const token = session.accessToken;
    const out: Array<{ id: string; updated_at?: string }> = [];
    let offset = 0;
    for (;;) {
      const r = await fetch(`/backend-api/conversations?offset=${offset}&limit=28&order=updated`, {
        credentials: 'include',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      const body = await r.json() as { items?: Array<{ id: string; update_time?: number }>; total?: number };
      const items = body.items ?? [];
      for (const it of items) out.push({ id: it.id, updated_at: it.update_time?.toString() });
      offset += items.length;
      if (items.length < 28) break;
      if (typeof body.total === 'number' && offset >= body.total) break;
    }
    return out;
  })();
}

function fetchChatgptConv(convId: string): Promise<unknown> {
  return (async () => {
    const session = await fetch('/api/auth/session', { credentials: 'include' }).then(r => r.json()) as { accessToken?: string };
    const token = session.accessToken;
    const r = await fetch(`/backend-api/conversation/${convId}`, {
      credentials: 'include',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    return r.json();
  })();
}
