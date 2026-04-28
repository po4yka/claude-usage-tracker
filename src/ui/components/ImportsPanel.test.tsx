import { describe, expect, it, vi } from 'vitest';

vi.hoisted(() => {
  Object.defineProperty(globalThis, 'window', {
    value: { location: { search: '' } },
    configurable: true,
  });
});

import { ImportsPanel } from './ImportsPanel';
import { archiveImports } from '../state/store';

// Helper: recursively collect all text content from a vnode tree.
function collectText(node: unknown): string[] {
  if (typeof node === 'string' || typeof node === 'number') return [String(node)];
  if (Array.isArray(node)) return node.flatMap(collectText);
  if (!node || typeof node !== 'object') return [];
  const vnode = node as { props?: { children?: unknown } };
  return collectText(vnode.props?.children);
}

describe('ImportsPanel', () => {
  it('shows the empty state when there are no imports', () => {
    archiveImports.value = [];
    const vnode = ImportsPanel({ onReload: async () => {} });
    const texts = collectText(vnode);
    expect(texts.some(t => t.includes('No imports yet'))).toBe(true);
  });

  it('renders a row per import', () => {
    archiveImports.value = [
      { import_id: '2026-04-28T120000.000000Z', vendor: 'openai', created_at: '2026-04-28T12:00:00Z', conversation_count: 12, parser_version: 1, schema_fingerprint: null },
      { import_id: '2026-04-27T120000.000000Z', vendor: 'anthropic', created_at: '2026-04-27T12:00:00Z', conversation_count: 7, parser_version: 1, schema_fingerprint: 'a1b2c3d4e5f6' },
    ];
    const vnode = ImportsPanel({ onReload: async () => {} });
    const texts = collectText(vnode);
    expect(texts.some(t => t.includes('openai'))).toBe(true);
    expect(texts.some(t => t.includes('anthropic'))).toBe(true);
    expect(texts.some(t => t.includes('a1b2c3d4e5f6'))).toBe(true);
  });

  it('calls onReload when the refresh button is clicked', async () => {
    archiveImports.value = [];
    const reload = vi.fn(async () => {});
    const vnode = ImportsPanel({ onReload: reload });

    // Find the "Refresh" button in the header children.
    const section = vnode as { props: { children: unknown[] } };
    const header = section.props.children[0] as { props: { children: unknown[] } };
    const btn = header.props.children[1] as { props: { onClick: () => void } };

    btn.props.onClick();
    await new Promise(r => setTimeout(r, 0));
    expect(reload).toHaveBeenCalled();
  });
});
