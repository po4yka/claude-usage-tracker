import { useMemo } from 'preact/hooks';
import { type ColumnDef, type SortingState } from '@tanstack/table-core';
import { fmt, fmtCost, anyHasCredits, fmtCredits } from '../lib/format';
import type { ProjectAgg } from '../state/types';

import { DataTable } from './DataTable';

const defaultSort: SortingState = [{ id: 'cost', desc: true }];

function useProjectColumns(showCredits: boolean): ColumnDef<ProjectAgg, any>[] {
  return useMemo(
    () => [
      {
        id: 'project',
        accessorKey: 'project',
        header: 'Project',
        enableSorting: false,
        cell: (info: any) => {
          const row = info.row.original as ProjectAgg;
          const label = row.display_name || row.project;
          return <span title={row.project}>{label}</span>;
        },
      },
      {
        id: 'sessions',
        accessorKey: 'sessions',
        header: 'Sessions',
        cell: (info: any) => <span class="num">{info.getValue()}</span>,
      },
      {
        id: 'turns',
        accessorKey: 'turns',
        header: 'Turns',
        cell: (info: any) => <span class="num">{fmt(info.getValue())}</span>,
      },
      {
        id: 'input',
        accessorKey: 'input',
        header: 'Input',
        cell: (info: any) => <span class="num">{fmt(info.getValue())}</span>,
      },
      {
        id: 'output',
        accessorKey: 'output',
        header: 'Output',
        cell: (info: any) => <span class="num">{fmt(info.getValue())}</span>,
      },
      {
        id: 'cost',
        accessorKey: 'cost',
        header: 'Est. Cost',
        cell: (info: any) => <span class="cost">{fmtCost(info.getValue())}</span>,
      },
      ...(showCredits ? [{
        id: 'credits',
        accessorFn: (row: ProjectAgg) => row.credits ?? null,
        header: 'Credits',
        sortUndefined: 'last' as const,
        cell: (info: any) => {
          const v = info.getValue() as number | null;
          return <span class="num">{fmtCredits(v)}</span>;
        },
      }] : []),
    ],
    [showCredits]
  );
}

export function ProjectCostTable({
  byProject,
  onExportCSV,
}: {
  byProject: ProjectAgg[];
  onExportCSV: () => void;
}) {
  const showCredits = anyHasCredits(byProject);
  const columns = useProjectColumns(showCredits);

  return (
    <DataTable
      columns={columns}
      data={byProject}
      title="Cost by Project"
      exportFn={onExportCSV}
      defaultSort={defaultSort}
      costRows
    />
  );
}
