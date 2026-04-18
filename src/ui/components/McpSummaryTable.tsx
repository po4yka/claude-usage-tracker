import { type ColumnDef } from '@tanstack/table-core';
import { fmt } from '../lib/format';
import type { McpServerSummary } from '../state/types';
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

function makeColumns(data: McpServerSummary[]): ColumnDef<McpServerSummary, any>[] {
  const maxInvocations = data.reduce((m, r) => Math.max(m, r.invocations), 0);
  return [
    { accessorKey: 'provider', header: 'Provider',
      cell: ({ getValue }) => <span class="model-tag">{String(getValue()).toUpperCase()}</span> },
    { accessorKey: 'server', header: 'MCP Server',
      cell: ({ getValue }) => <span class="model-tag mcp">{String(getValue())}</span> },
    { accessorKey: 'tools_used', header: 'Tools',
      cell: ({ getValue }) => <span class="num">{getValue()}</span> },
    { accessorKey: 'invocations', header: 'Calls',
      cell: ({ getValue }) => (
        <RankBar
          value={getValue() as number}
          max={maxInvocations}
          label={fmt(getValue() as number)}
        />
      ) },
    { accessorKey: 'sessions_used', header: 'Sessions',
      cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  ];
}

export function McpSummaryTable({ data }: { data: McpServerSummary[] }) {
  if (!data.length) return null;
  return <DataTable columns={makeColumns(data)} data={data} title="MCP Server Usage" />;
}
