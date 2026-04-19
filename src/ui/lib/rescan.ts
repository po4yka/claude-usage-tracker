export interface RescanButtonLike {
  disabled: boolean;
  textContent: string | null;
}

export interface RescanResponse {
  ok: boolean;
  status: number;
  statusText: string;
  json(): Promise<{ new: number; updated: number }>;
}

export interface TriggerRescanDeps {
  button: RescanButtonLike;
  fetchImpl: (input: string, init: { method: string }) => Promise<RescanResponse>;
  loadData: (force?: boolean) => Promise<void>;
  showError: (message: string) => void;
  setTimer: (callback: () => void, delayMs: number) => unknown;
  logError?: (error: unknown) => void;
}

export function createTriggerRescan({
  button,
  fetchImpl,
  loadData,
  showError,
  setTimer,
  logError = () => undefined,
}: TriggerRescanDeps): () => Promise<void> {
  return async function triggerRescan(): Promise<void> {
    button.disabled = true;
    button.textContent = '\u21bb Scanning…';

    try {
      const resp = await fetchImpl('/api/rescan', { method: 'POST' });
      if (!resp.ok) {
        showError(`Rescan failed: HTTP ${resp.status} ${resp.statusText}`);
        button.textContent = '\u21bb Rescan (failed)';
        return;
      }

      const data = await resp.json();
      button.textContent = '\u21bb Rescan (' + data.new + ' new, ' + data.updated + ' updated)';
      await loadData(true);
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      showError('Rescan failed: ' + msg);
      button.textContent = '\u21bb Rescan (error)';
      logError(error);
    } finally {
      setTimer(() => {
        button.textContent = '\u21bb Rescan';
        button.disabled = false;
      }, 3000);
    }
  };
}
