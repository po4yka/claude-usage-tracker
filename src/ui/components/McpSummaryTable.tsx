import { type ColumnDef } from '@tanstack/table-core';
import { fmt } from '../lib/format';
import type { McpServerSummary } from '../state/types';
import { DataTable } from './DataTable';

const columns: ColumnDef<McpServerSummary, any>[] = [
  { accessorKey: 'server', header: 'MCP Server',
    cell: ({ getValue }) => <span class="model-tag mcp">{String(getValue())}</span> },
  { accessorKey: 'tools_used', header: 'Tools',
    cell: ({ getValue }) => <span class="num">{getValue()}</span> },
  { accessorKey: 'invocations', header: 'Calls',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'sessions_used', header: 'Sessions',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
];

export function McpSummaryTable({ data }: { data: McpServerSummary[] }) {
  if (!data.length) return null;
  return <DataTable columns={columns} data={data} title="MCP Server Usage" />;
}
