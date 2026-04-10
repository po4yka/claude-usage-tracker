import { type ColumnDef } from '@tanstack/table-core';
import { fmt } from '../lib/format';
import type { VersionSummary } from '../state/types';
import { DataTable } from './DataTable';

const columns: ColumnDef<VersionSummary, any>[] = [
  { accessorKey: 'version', header: 'Version',
    cell: ({ getValue }) => <span class="model-tag">{String(getValue())}</span> },
  { accessorKey: 'turns', header: 'Turns',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'sessions', header: 'Sessions',
    cell: ({ getValue }) => <span class="num">{getValue()}</span> },
];

export function VersionTable({ data }: { data: VersionSummary[] }) {
  if (!data.length) return null;
  return <DataTable columns={columns} data={data} title="Claude Code Versions" />;
}
