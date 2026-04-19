import { type ColumnDef } from '@tanstack/table-core';
import { fmt, fmtCost } from '../lib/format';
import type { BranchSummary } from '../state/types';
import { DataTable } from './DataTable';

/** Inline proportional bar — renders a background fill behind the cell text.
 *  The bar width is (value / max) * 100 % at 12 % opacity using the primary
 *  text colour so it respects both dark and light themes. */
function RankBar({ value, max, label }: { value: number; max: number; label: string }) {
  const pct = max > 0 ? (value / max) * 100 : 0;
  const tooltip = `${value} (${pct.toFixed(1)}% of max ${max})`;
  return (
    <span
      style={{ position: 'relative', display: 'inline-block', width: '100%' }}
      title={tooltip}
    >
      <span
        data-testid="rank-bar"
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          bottom: 0,
          width: `${pct}%`,
          backgroundColor: 'var(--color-text-primary)',
          opacity: 0.12,
          pointerEvents: 'none',
        }}
      />
      <span class="num" style={{ position: 'relative', zIndex: 1 }}>{label}</span>
    </span>
  );
}

function makeColumns(data: BranchSummary[]): ColumnDef<BranchSummary, any>[] {
  const maxSessions = data.reduce((m, r) => Math.max(m, r.sessions), 0);
  return [
    { accessorKey: 'provider', header: 'Provider',
      cell: ({ getValue }) => <span class="model-tag">{String(getValue()).toUpperCase()}</span> },
    { accessorKey: 'branch', header: 'Branch',
      cell: ({ getValue }) => <span class="model-tag">{String(getValue())}</span> },
    { accessorKey: 'sessions', header: 'Sessions',
      cell: ({ getValue }) => (
        <RankBar
          value={getValue() as number}
          max={maxSessions}
          label={String(getValue())}
        />
      ) },
    { accessorKey: 'turns', header: 'Turns',
      cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
    { accessorKey: 'input', header: 'Input',
      cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
    { accessorKey: 'output', header: 'Output',
      cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
    { accessorKey: 'cost', header: 'Est. Cost',
      cell: ({ getValue }) => <span class="cost">{fmtCost(getValue() as number)}</span> },
  ];
}

export function BranchTable({ data }: { data: BranchSummary[] }) {
  if (!data.length) return null;
  return <DataTable columns={makeColumns(data)} data={data} title="Usage by Git Branch" sectionKey="branch-summary" />;
}
