import { fmt, fmtCost } from '../lib/format';
import { modelSortCol, modelSortDir } from '../state/store';
import type { ModelAgg } from '../state/types';

function setModelSort(col: string): void {
  if (modelSortCol.value === col) {
    modelSortDir.value = modelSortDir.value === 'desc' ? 'asc' : 'desc';
  } else {
    modelSortCol.value = col;
    modelSortDir.value = 'desc';
  }
}

function sortModels(byModel: ModelAgg[]): ModelAgg[] {
  const col = modelSortCol.value;
  const dir = modelSortDir.value;
  return [...byModel].sort((a, b) => {
    let av: number, bv: number;
    if (col === 'cost') {
      av = a.cost;
      bv = b.cost;
    } else {
      av = (a as any)[col] ?? 0;
      bv = (b as any)[col] ?? 0;
    }
    if (av < bv) return dir === 'desc' ? 1 : -1;
    if (av > bv) return dir === 'desc' ? -1 : 1;
    return 0;
  });
}

export function ModelCostTable({ byModel }: { byModel: ModelAgg[] }) {
  const sortCol = modelSortCol.value;
  const sortDir = modelSortDir.value;
  const sorted = sortModels(byModel);

  const sortIcon = (col: string) =>
    sortCol === col ? (sortDir === 'desc' ? ' \u25bc' : ' \u25b2') : '';

  return (
    <div class="table-card">
      <div class="section-title">Cost by Model</div>
      <table>
        <thead>
          <tr>
            <th>Model</th>
            <th class="sortable" onClick={() => setModelSort('turns')}>Turns<span class="sort-icon">{sortIcon('turns')}</span></th>
            <th class="sortable" onClick={() => setModelSort('input')}>Input<span class="sort-icon">{sortIcon('input')}</span></th>
            <th class="sortable" onClick={() => setModelSort('output')}>Output<span class="sort-icon">{sortIcon('output')}</span></th>
            <th class="sortable" onClick={() => setModelSort('cache_read')}>Cache Read<span class="sort-icon">{sortIcon('cache_read')}</span></th>
            <th class="sortable" onClick={() => setModelSort('cache_creation')}>Cache Creation<span class="sort-icon">{sortIcon('cache_creation')}</span></th>
            <th class="sortable" onClick={() => setModelSort('cost')}>Est. Cost<span class="sort-icon">{sortIcon('cost')}</span></th>
          </tr>
        </thead>
        <tbody>
          {sorted.map(m => (
            <tr key={m.model}>
              <td><span class="model-tag">{m.model}</span></td>
              <td class="num">{fmt(m.turns)}</td>
              <td class="num">{fmt(m.input)}</td>
              <td class="num">{fmt(m.output)}</td>
              <td class="num">{fmt(m.cache_read)}</td>
              <td class="num">{fmt(m.cache_creation)}</td>
              {m.is_billable
                ? <td class="cost">{fmtCost(m.cost)}</td>
                : <td class="cost-na">n/a</td>}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
