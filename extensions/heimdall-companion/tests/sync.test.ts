import { beforeAll, describe, expect, it, vi } from 'vitest';
import { pickChanged, schemaFingerprint, syncVendor, type VendorAdapter } from '../src/sync';
import { DEFAULT_CONFIG } from '../src/types';

beforeAll(() => {
  // Stub chrome globals required by storage.ts (loadConfig/saveConfig path)
  // and heimdall.ts (postHeartbeat reads runtime.getManifest).
  (globalThis as unknown as { chrome: unknown }).chrome = {
    storage: { local: { get: async () => ({}), set: async () => undefined } },
    runtime: { getManifest: () => ({ version: '0.1.0' }) },
  };
});

describe('pickChanged', () => {
  it('returns ids never seen', () => {
    expect(pickChanged({}, [{ id: 'a', updated_at: 't' }])).toEqual(['a']);
  });
  it('returns ids whose updated_at advanced', () => {
    expect(pickChanged({ a: '1' }, [{ id: 'a', updated_at: '2' }])).toEqual(['a']);
  });
  it('skips ids whose updated_at is unchanged', () => {
    expect(pickChanged({ a: '2' }, [{ id: 'a', updated_at: '2' }])).toEqual([]);
  });
  it('fetches id with no updated_at only if never seen', () => {
    expect(pickChanged({}, [{ id: 'b' }])).toEqual(['b']);
    expect(pickChanged({ b: '2026' }, [{ id: 'b' }])).toEqual([]);
  });
});

describe('schemaFingerprint', () => {
  it('is stable across key order', async () => {
    const a = await schemaFingerprint({ x: 1, y: 2 });
    const b = await schemaFingerprint({ y: 2, x: 1 });
    expect(a).toBe(b);
  });
  it('returns empty string for non-objects', async () => {
    expect(await schemaFingerprint(null)).toBe('');
    expect(await schemaFingerprint(42)).toBe('');
  });
  it('returns a 64-char hex string for a plain object', async () => {
    const fp = await schemaFingerprint({ a: 1 });
    expect(fp).toMatch(/^[0-9a-f]{64}$/);
  });
});

describe('syncVendor', () => {
  it('lists, diffs, fetches, posts, and updates lastSeen', async () => {
    vi.spyOn(globalThis as unknown as { fetch: typeof fetch }, 'fetch').mockImplementation(
      async () => new Response(JSON.stringify({ saved: true }), { status: 200 }),
    );
    const adapter: VendorAdapter = {
      vendor: 'claude.ai',
      list: async () => [{ id: 'c1', updated_at: 't1' }],
      fetch: async (_id: string) => ({ payload: 1 }),
    };
    const cfg = structuredClone(DEFAULT_CONFIG);
    cfg.companionToken = 'tok';
    const result = await syncVendor(cfg, adapter);
    expect(result.listed).toBe(1);
    expect(result.written).toBe(1);
    expect(cfg.vendors['claude.ai']?.lastSeenUpdatedAt['c1']).toBe('t1');
    vi.restoreAllMocks();
  });

  it('skips disabled vendors', async () => {
    const adapter: VendorAdapter = {
      vendor: 'claude.ai',
      list: async () => [],
      fetch: async (_id: string) => ({}),
    };
    const cfg = structuredClone(DEFAULT_CONFIG);
    const vendorState = cfg.vendors['claude.ai'];
    if (vendorState) vendorState.enabled = false;
    const result = await syncVendor(cfg, adapter);
    expect(result.listed).toBe(0);
  });

  it('records list errors and returns early', async () => {
    const adapter: VendorAdapter = {
      vendor: 'claude.ai',
      list: async () => { throw new Error('network down'); },
      fetch: async (_id: string) => ({}),
    };
    const cfg = structuredClone(DEFAULT_CONFIG);
    cfg.companionToken = 'tok';
    const result = await syncVendor(cfg, adapter);
    expect(result.errors).toHaveLength(1);
    expect(result.errors[0]).toMatch(/list: network down/);
    expect(result.listed).toBe(0);
  });
});
