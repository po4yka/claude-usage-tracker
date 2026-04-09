import { ApexChart } from './ApexChart';
import { MODEL_COLORS, apexThemeMode, cssVar } from '../lib/charts';
import { fmt } from '../lib/format';
import type { ModelAgg } from '../state/types';

export function ModelChart({ byModel }: { byModel: ModelAgg[] }) {
  if (!byModel.length) return null;

  const options = {
    chart: { type: 'donut', height: '100%', background: 'transparent', fontFamily: 'inherit' },
    theme: { mode: apexThemeMode() },
    series: byModel.map(m => m.input + m.output),
    labels: byModel.map(m => m.model),
    colors: MODEL_COLORS.slice(0, byModel.length),
    legend: { position: 'bottom', fontSize: '11px' },
    dataLabels: { enabled: false },
    tooltip: { y: { formatter: (v: number) => fmt(v) + ' tokens' } },
    stroke: { width: 2, colors: [cssVar('--card')] },
    plotOptions: { pie: { donut: { size: '60%' } } },
  };

  return <ApexChart options={options} id="chart-model" />;
}
