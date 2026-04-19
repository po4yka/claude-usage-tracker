import { ApexChart } from './ApexChart';
import { industrialChartOptions, tokenSeriesColors } from '../lib/charts';
import { fmt, truncateMid } from '../lib/format';
import type { ProjectAgg } from '../state/types';

export function ProjectChart({ byProject }: { byProject: ProjectAgg[] }) {
  const top = byProject.slice(0, 10);
  if (!top.length) return null;

  const base = industrialChartOptions('bar');
  const colors = tokenSeriesColors();
  // Collapse Input + Output into a single Total-tokens series. The
  // per-type breakdown already lives in ProjectCostTable below; a single
  // bar makes the first-fold "which project is biggest?" answerable at a
  // glance and sidesteps the near-invisible Output stripe.
  const totals = top.map(p => p.input + p.output);
  // Log scale on the value axis rescues tail bars (projects <3M were
  // rendering as hairlines next to a ~145M leader). ApexCharts uses the
  // `yaxis.logarithmic` option for horizontal bars' value axis.
  const hasValidLog = totals.every(v => v > 0);
  const options = {
    ...base,
    chart: { ...base.chart, type: 'bar' },
    series: [{ name: 'Total tokens', data: totals }],
    colors: [colors[0]],
    fill: { type: 'solid' },
    plotOptions: { bar: { horizontal: true, barHeight: '60%', borderRadius: 0 } },
    xaxis: {
      ...base.xaxis,
      categories: top.map(p => truncateMid(p.display_name || p.project, 18, 8)),
      labels: {
        ...base.xaxis.labels,
        formatter: (v: number) => fmt(v),
        hideOverlappingLabels: true,
      },
      tickAmount: 4,
    },
    yaxis: {
      ...base.yaxis,
      labels: { ...base.yaxis.labels, maxWidth: 120 },
      ...(hasValidLog ? { logarithmic: true, logBase: 10, forceNiceScale: false } : {}),
    },
    // Anchor the tooltip to the plot's top-left with negative offset so it
    // cannot cover the card's "TOP PROJECTS" title on hover.
    tooltip: {
      ...base.tooltip,
      fixed: { enabled: true, position: 'topLeft', offsetX: 0, offsetY: -8 },
      y: { formatter: (v: number) => fmt(v) + ' tokens' },
    },
  };

  return <ApexChart options={options} id="chart-project" />;
}
