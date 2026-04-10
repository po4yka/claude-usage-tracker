import { type ColumnDef } from '@tanstack/table-core';
import { fmt, fmtCost } from '../lib/format';
import type { BranchSummary } from '../state/types';
import { DataTable } from './DataTable';

const columns: ColumnDef<BranchSummary, any>[] = [
  { accessorKey: 'provider', header: 'Provider',
    cell: ({ getValue }) => <span class="model-tag">{String(getValue()).toUpperCase()}</span> },
  { accessorKey: 'branch', header: 'Branch',
    cell: ({ getValue }) => <span class="model-tag">{String(getValue())}</span> },
  { accessorKey: 'sessions', header: 'Sessions',
    cell: ({ getValue }) => <span class="num">{getValue()}</span> },
  { accessorKey: 'turns', header: 'Turns',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'input', header: 'Input',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'output', header: 'Output',
    cell: ({ getValue }) => <span class="num">{fmt(getValue() as number)}</span> },
  { accessorKey: 'cost', header: 'Est. Cost',
    cell: ({ getValue }) => <span class="cost">{fmtCost(getValue() as number)}</span> },
];

export function BranchTable({ data }: { data: BranchSummary[] }) {
  if (!data.length) return null;
  return <DataTable columns={columns} data={data} title="Usage by Git Branch" />;
}
