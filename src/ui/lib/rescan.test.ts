import { describe, expect, it, vi } from 'vitest';

import { createTriggerRescan, type RescanButtonLike } from './rescan';

describe('createTriggerRescan', () => {
  it('re-enables the button after an HTTP failure', async () => {
    const button: RescanButtonLike = { disabled: false, textContent: 'Rescan' };
    const errors: string[] = [];
    const timers: Array<() => void> = [];

    const triggerRescan = createTriggerRescan({
      button,
      fetchImpl: async () => ({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        json: async () => ({ new: 0, updated: 0 }),
      }),
      loadData: vi.fn(async () => undefined),
      showError: (message) => errors.push(message),
      setTimer: (callback) => {
        timers.push(callback);
        return timers.length;
      },
    });

    await triggerRescan();

    expect(button.disabled).toBe(true);
    expect(button.textContent).toBe('\u21bb Rescan (failed)');
    expect(errors).toEqual(['Rescan failed: HTTP 500 Internal Server Error']);
    expect(timers).toHaveLength(1);

    timers[0]!();
    expect(button.disabled).toBe(false);
    expect(button.textContent).toBe('\u21bb Rescan');
  });
});
