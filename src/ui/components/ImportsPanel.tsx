import { archiveImports, type ImportMeta } from '../state/store';
import { esc } from '../lib/format';

export interface ImportsPanelProps {
  onReload: () => Promise<void>;
}

export function ImportsPanel({ onReload }: ImportsPanelProps) {
  const imports = archiveImports.value;
  return (
    <section class="imports-panel">
      <header class="imports-panel-header">
        <h2>Imports</h2>
        <button type="button" onClick={() => void onReload()}>Refresh</button>
      </header>
      {imports.length === 0 && (
        <p class="imports-panel-empty">
          No imports yet. To bring in your web-chat history, request a data
          export from claude.ai or chatgpt.com (Settings &rarr; Export data) and
          drop the resulting ZIP onto Heimdall via{' '}
          <code>heimdall import-export &lt;zip&gt;</code> or run{' '}
          <code>heimdall import-export --watch ~/Downloads</code>.
        </p>
      )}
      {imports.length > 0 && (
        <table class="data-table">
          <thead>
            <tr>
              <th>VENDOR</th>
              <th>IMPORTED</th>
              <th>CONVERSATIONS</th>
              <th>SCHEMA FINGERPRINT</th>
            </tr>
          </thead>
          <tbody>
            {imports.map((m: ImportMeta) => (
              <tr key={m.import_id}>
                <td>{esc(m.vendor)}</td>
                <td>{esc(m.created_at)}</td>
                <td>{m.conversation_count}</td>
                <td><code>{esc((m.schema_fingerprint || '—').slice(0, 12))}</code></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
