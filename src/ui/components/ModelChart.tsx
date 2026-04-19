import { ApexChart } from './ApexChart';
import { industrialChartOptions, modelSeriesColors, cssVar } from '../lib/charts';
import { fmt } from '../lib/format';
import type { ModelAgg } from '../state/types';

export function ModelChart({ byModel }: { byModel: ModelAgg[] }) {
  if (!byModel.length) return null;

  // Collapse the long tail into an "Other" slice so the legend stays short
  // enough to leave room for the donut in a 240px-tall chart card. Without
  // this, 10+ models crowd the bottom legend and squeeze the donut to
  // ~60x95px.
  const sorted = [...byModel].sort((a, b) => (b.input + b.output) - (a.input + a.output));
  const TOP_N = 4;
  const top = sorted.slice(0, TOP_N);
  const rest = sorted.slice(TOP_N);
  const series = top.map(m => m.input + m.output);
  const labels = top.map(m => m.model);
  if (rest.length > 0) {
    const otherTotal = rest.reduce((s, m) => s + m.input + m.output, 0);
    if (otherTotal > 0) {
      series.push(otherTotal);
      labels.push(`Other (${rest.length})`);
    }
  }

  const base = industrialChartOptions('donut');
  const options = {
    ...base,
    chart: { ...base.chart, type: 'donut' },
    series,
    labels,
    colors: modelSeriesColors(labels.length),
    stroke: { width: 2, colors: [cssVar('--surface')] },
    plotOptions: {
      pie: {
        donut: {
          size: '64%',
          labels: {
            show: true,
            total: {
              show: true,
              label: 'TOTAL',
              fontFamily: 'var(--font-mono), "Space Mono", monospace',
              fontSize: '11px',
              color: cssVar('--text-secondary'),
              formatter: (w: any) =>
                fmt(w.globals.seriesTotals.reduce((a: number, b: number) => a + b, 0)),
            },
            value: {
              fontFamily: 'var(--font-mono), "Space Mono", monospace',
              fontSize: '20px',
              color: cssVar('--text-display'),
              formatter: (val: string) => fmt(Number(val)),
            },
            name: {
              fontFamily: 'var(--font-mono), "Space Mono", monospace',
              fontSize: '11px',
              color: cssVar('--text-secondary'),
            },
          },
        },
      },
    },
    tooltip: { ...base.tooltip, y: { formatter: (v: number) => fmt(v) + ' tokens' } },
  };

  return <ApexChart options={options} id="chart-model" />;
}
