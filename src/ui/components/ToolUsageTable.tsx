import { type ColumnDef } from '@tanstack/table-core';
import { fmt } from '../lib/format';
import type { ToolSummary } from '../state/types';
import { DataTable } from './DataTable';

const columns: ColumnDef<ToolSummary, any>[] = [
  { accessorKey: 'tool_name', header: 'Tool',
    cell: ({ row }) => {
      const cat = row.original.category;
      const badge = cat === 'mcp' ? 'mcp' : 'builtin';
      return (
        <span>
          <span class={`model-tag ${badge}`}>{cat}</span>{' '}
          {row.original.tool_name}
        </span>
      );
    } },
  { accessorKey: 'mcp_server', header: 'MCP Server',
    cell: ({ getValue }) => {
      const v = getValue() as string | null;
      return v ? <span class="dim">{v}</span> : <span class="dim">--</span>;
    } },
  { accessorKey: 'invocations', header: 'Calls',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'turns_used', header: 'Turns',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'sessions_used', header: 'Sessions',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
];

export function ToolUsageTable({ data }: { data: ToolSummary[] }) {
  if (!data.length) return null;
  return <DataTable columns={columns} data={data} title="Tool Usage" />;
}
