import { fmt, fmtCost } from '../lib/format';
import { projectSortCol, projectSortDir } from '../state/store';
import type { ProjectAgg } from '../state/types';

function setProjectSort(col: string): void {
  if (projectSortCol.value === col) {
    projectSortDir.value = projectSortDir.value === 'desc' ? 'asc' : 'desc';
  } else {
    projectSortCol.value = col;
    projectSortDir.value = 'desc';
  }
}

function sortProjects(byProject: ProjectAgg[]): ProjectAgg[] {
  const col = projectSortCol.value;
  const dir = projectSortDir.value;
  return [...byProject].sort((a, b) => {
    const av = (a as any)[col] ?? 0;
    const bv = (b as any)[col] ?? 0;
    if (av < bv) return dir === 'desc' ? 1 : -1;
    if (av > bv) return dir === 'desc' ? -1 : 1;
    return 0;
  });
}

export function ProjectCostTable({ byProject, onExportCSV }: { byProject: ProjectAgg[]; onExportCSV: () => void }) {
  const sortCol = projectSortCol.value;
  const sortDir = projectSortDir.value;
  const sorted = sortProjects(byProject);

  const sortIcon = (col: string) =>
    sortCol === col ? (sortDir === 'desc' ? ' \u25bc' : ' \u25b2') : '';

  return (
    <div class="table-card">
      <div class="section-header">
        <div class="section-title">Cost by Project</div>
        <button class="export-btn" onClick={onExportCSV} title="Export projects to CSV">&#x2913; CSV</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Project</th>
            <th class="sortable" onClick={() => setProjectSort('sessions')}>Sessions<span class="sort-icon">{sortIcon('sessions')}</span></th>
            <th class="sortable" onClick={() => setProjectSort('turns')}>Turns<span class="sort-icon">{sortIcon('turns')}</span></th>
            <th class="sortable" onClick={() => setProjectSort('input')}>Input<span class="sort-icon">{sortIcon('input')}</span></th>
            <th class="sortable" onClick={() => setProjectSort('output')}>Output<span class="sort-icon">{sortIcon('output')}</span></th>
            <th class="sortable" onClick={() => setProjectSort('cost')}>Est. Cost<span class="sort-icon">{sortIcon('cost')}</span></th>
          </tr>
        </thead>
        <tbody>
          {sorted.map(p => (
            <tr key={p.project}>
              <td>{p.project}</td>
              <td class="num">{p.sessions}</td>
              <td class="num">{fmt(p.turns)}</td>
              <td class="num">{fmt(p.input)}</td>
              <td class="num">{fmt(p.output)}</td>
              <td class="cost">{fmtCost(p.cost)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
