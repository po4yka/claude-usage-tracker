import { fmt, fmtCost } from '../lib/format';
import {
  sessionSortCol,
  sessionSortDir,
  sessionsCurrentPage,
  lastFilteredSessions,
  SESSIONS_PAGE_SIZE,
} from '../state/store';
import type { SessionRow, SortDir } from '../state/types';

function setSessionSort(col: string): void {
  if (sessionSortCol.value === col) {
    sessionSortDir.value = sessionSortDir.value === 'desc' ? 'asc' : 'desc';
  } else {
    sessionSortCol.value = col;
    sessionSortDir.value = 'desc';
  }
}

function sortSessions(sessions: SessionRow[]): SessionRow[] {
  const col = sessionSortCol.value;
  const dir = sessionSortDir.value;
  return [...sessions].sort((a, b) => {
    let av: number | string, bv: number | string;
    if (col === 'cost') {
      av = a.cost;
      bv = b.cost;
    } else if (col === 'duration_min') {
      av = a.duration_min || 0;
      bv = b.duration_min || 0;
    } else {
      av = (a as any)[col] ?? 0;
      bv = (b as any)[col] ?? 0;
    }
    if (av < bv) return dir === 'desc' ? 1 : -1;
    if (av > bv) return dir === 'desc' ? -1 : 1;
    return 0;
  });
}

export function SessionsTable({ onExportCSV }: { onExportCSV: () => void }) {
  const sortCol = sessionSortCol.value;
  const sortDir = sessionSortDir.value;
  const page = sessionsCurrentPage.value;
  const allSessions = lastFilteredSessions.value;

  const sorted = sortSessions(allSessions);
  const start = page * SESSIONS_PAGE_SIZE;
  const pageData = sorted.slice(start, start + SESSIONS_PAGE_SIZE);
  const maxPage = Math.max(0, Math.ceil(sorted.length / SESSIONS_PAGE_SIZE) - 1);

  const sortIcon = (col: string) =>
    sortCol === col ? (sortDir === 'desc' ? ' \u25bc' : ' \u25b2') : '';

  return (
    <div class="table-card">
      <div class="section-header">
        <div class="section-title">Recent Sessions</div>
        <button class="export-btn" onClick={onExportCSV} title="Export filtered sessions to CSV">&#x2913; CSV</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Session</th>
            <th>Project</th>
            <th class="sortable" onClick={() => setSessionSort('last')}>Last Active<span class="sort-icon">{sortIcon('last')}</span></th>
            <th class="sortable" onClick={() => setSessionSort('duration_min')}>Duration<span class="sort-icon">{sortIcon('duration_min')}</span></th>
            <th>Model</th>
            <th class="sortable" onClick={() => setSessionSort('turns')}>Turns<span class="sort-icon">{sortIcon('turns')}</span></th>
            <th class="sortable" onClick={() => setSessionSort('input')}>Input<span class="sort-icon">{sortIcon('input')}</span></th>
            <th class="sortable" onClick={() => setSessionSort('output')}>Output<span class="sort-icon">{sortIcon('output')}</span></th>
            <th class="sortable" onClick={() => setSessionSort('cost')}>Est. Cost<span class="sort-icon">{sortIcon('cost')}</span></th>
          </tr>
        </thead>
        <tbody>
          {pageData.map(s => (
            <tr key={s.session_id}>
              <td class="muted" style={{ fontFamily: 'monospace' }}>{s.session_id}&hellip;</td>
              <td>{s.project}</td>
              <td class="muted">{s.last}</td>
              <td class="muted">{s.duration_min}m</td>
              <td><span class="model-tag">{s.model}</span></td>
              <td class="num">{s.turns}{s.subagent_count > 0 && <span class="muted" style={{ fontSize: '10px' }}> ({s.subagent_count} agents)</span>}</td>
              <td class="num">{fmt(s.input)}</td>
              <td class="num">{fmt(s.output)}</td>
              {s.is_billable
                ? <td class="cost">{fmtCost(s.cost)}</td>
                : <td class="cost-na">n/a</td>}
            </tr>
          ))}
        </tbody>
      </table>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '12px', fontSize: '12px', color: 'var(--muted)' }}>
        <span>{sorted.length > 0 ? `Showing ${start + 1}\u2013${Math.min(start + SESSIONS_PAGE_SIZE, sorted.length)} of ${sorted.length}` : 'No sessions'}</span>
        <div style={{ display: 'flex', gap: '6px' }}>
          <button class="filter-btn" disabled={page <= 0} onClick={() => { sessionsCurrentPage.value = Math.max(0, page - 1); }}>&laquo; Prev</button>
          <button class="filter-btn" disabled={page >= maxPage} onClick={() => { sessionsCurrentPage.value = Math.min(maxPage, page + 1); }}>Next &raquo;</button>
        </div>
      </div>
    </div>
  );
}
