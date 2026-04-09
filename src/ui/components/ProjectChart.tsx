import { ApexChart } from './ApexChart';
import { TOKEN_COLORS, apexThemeMode, cssVar } from '../lib/charts';
import { fmt } from '../lib/format';
import type { ProjectAgg } from '../state/types';

export function ProjectChart({ byProject }: { byProject: ProjectAgg[] }) {
  const top = byProject.slice(0, 10);
  if (!top.length) return null;

  const options = {
    chart: { type: 'bar', height: '100%', background: 'transparent',
             toolbar: { show: false }, fontFamily: 'inherit' },
    theme: { mode: apexThemeMode() },
    series: [
      { name: 'Input',  data: top.map(p => p.input) },
      { name: 'Output', data: top.map(p => p.output) },
    ],
    colors: [TOKEN_COLORS.input, TOKEN_COLORS.output],
    plotOptions: { bar: { horizontal: true, barHeight: '60%' } },
    xaxis: { categories: top.map(p => p.project.length > 22 ? '\u2026' + p.project.slice(-20) : p.project),
             labels: { formatter: (v: number) => fmt(v) } },
    yaxis: { labels: { maxWidth: 160 } },
    legend: { position: 'top', fontSize: '11px' },
    dataLabels: { enabled: false },
    tooltip: { y: { formatter: (v: number) => fmt(v) + ' tokens' } },
    grid: { borderColor: cssVar('--chart-grid') },
  };

  return <ApexChart options={options} id="chart-project" />;
}
