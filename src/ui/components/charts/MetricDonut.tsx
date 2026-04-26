import { ApexChart } from './ApexChart';
import { dashboardChartOptions, cssVar, withAlpha } from '../../lib/charts';
import { esc } from '../../lib/format';

export interface MetricDonutProps<Row, Metric extends string> {
  rows: Row[];
  metric: Metric;
  metricOptions: Metric[];
  metricLabel: (m: Metric) => string;
  metricValue: (row: Row, m: Metric) => number;
  metricFormat: (value: number, m: Metric, large?: boolean) => string;
  rowLabel: (row: Row) => string;
  rowCost: (row: Row) => number;
  rowCalls: (row: Row) => number;
  rowTokens: (row: Row) => number;
  id: string;
  centerKickerPrefix?: string | undefined;
  onMetricChange?: ((next: Metric) => void) | undefined;
  /** When a metric button should be disabled. Defaults to () => false. */
  isMetricDisabled?: ((m: Metric) => boolean) | undefined;
  /** Render a legend list below the ring. Defaults to false. */
  showLegend?: boolean;
  /** Called when a non-"Other" legend row is clicked. */
  onSelectRow?: ((label: string) => void) | undefined;
  /** Called when the chart slice is clicked. */
  onSliceClick?: ((label: string) => void) | undefined;
  /** Format cost in tooltip. */
  formatCost: (value: number) => string;
  /** Format calls in tooltip. */
  formatCalls: (value: number) => string;
  /** Format tokens in tooltip. */
  formatTokens: (value: number) => string;
}

interface DonutRow {
  label: string;
  value: number;
  share: number;
  cost: number;
  calls: number;
  tokens: number;
  color: string;
  isOther: boolean;
}

const SLICE_OPACITY_LADDER = [1.0, 0.64, 0.46, 0.34, 0.24, 0.16];
const TOP_N = 5;

function formatShare(share: number): string {
  if (share >= 99.5) return '100%';
  if (share >= 10) return `${share.toFixed(0)}%`;
  if (share >= 0.1) return `${share.toFixed(1)}%`;
  if (share > 0) return '<0.1%';
  return '0%';
}

export function MetricDonut<Row, Metric extends string>({
  rows,
  metric,
  metricOptions,
  metricLabel,
  metricValue,
  metricFormat,
  rowLabel,
  rowCost,
  rowCalls,
  rowTokens,
  id,
  centerKickerPrefix = '',
  onMetricChange,
  isMetricDisabled,
  showLegend = false,
  onSelectRow,
  onSliceClick,
  formatCost,
  formatCalls,
  formatTokens,
}: MetricDonutProps<Row, Metric>) {
  if (!rows.length) return null;

  const sorted = rows
    .map(row => ({ row, value: metricValue(row, metric) }))
    .filter(entry => entry.value > 0)
    .sort((a, b) => b.value - a.value);

  if (!sorted.length) return null;

  const top = sorted.slice(0, TOP_N);
  const rest = sorted.slice(TOP_N);
  const total = sorted.reduce((sum, entry) => sum + entry.value, 0);

  const donutRows: DonutRow[] = top.map((entry, index) => ({
    label: rowLabel(entry.row),
    value: entry.value,
    share: total > 0 ? (entry.value / total) * 100 : 0,
    cost: rowCost(entry.row),
    calls: rowCalls(entry.row),
    tokens: rowTokens(entry.row),
    color: withAlpha('--text-display', SLICE_OPACITY_LADDER[Math.min(index, SLICE_OPACITY_LADDER.length - 1)] ?? 0.16),
    isOther: false,
  }));

  const otherValue = rest.reduce((sum, entry) => sum + entry.value, 0);
  const hasOther = otherValue > 0;
  if (hasOther) {
    donutRows.push({
      label: `Other (${rest.length})`,
      value: otherValue,
      share: total > 0 ? (otherValue / total) * 100 : 0,
      cost: rest.reduce((sum, entry) => sum + rowCost(entry.row), 0),
      calls: rest.reduce((sum, entry) => sum + rowCalls(entry.row), 0),
      tokens: rest.reduce((sum, entry) => sum + rowTokens(entry.row), 0),
      color: withAlpha('--text-display', SLICE_OPACITY_LADDER[Math.min(donutRows.length, SLICE_OPACITY_LADDER.length - 1)] ?? 0.16),
      isOther: true,
    });
  }

  const base = dashboardChartOptions('donut');
  const options = {
    ...base,
    chart: {
      ...base.chart,
      type: 'donut',
      ...(onSliceClick
        ? {
            events: {
              dataPointSelection: (
                _event: unknown,
                _ctx: unknown,
                config: { dataPointIndex: number }
              ) => {
                const row = donutRows[config.dataPointIndex];
                if (row && !row.isOther) onSliceClick(row.label);
              },
            },
          }
        : {}),
    },
    series: donutRows.map(row => row.value),
    labels: donutRows.map(row => row.label),
    colors: donutRows.map(row => row.color),
    stroke: { width: 2, colors: [cssVar('--surface')] },
    legend: { ...base.legend, show: false },
    states: {
      hover: { filter: { type: 'none', value: 0 } },
      active: { filter: { type: 'none', value: 0 } },
    },
    tooltip: {
      ...base.tooltip,
      custom: ({ seriesIndex }: { seriesIndex: number }) => {
        const row = donutRows[seriesIndex];
        if (!row) return '';
        return (
          `<div style="padding:8px 12px;font-family:var(--font-mono,'Geist Mono',ui-monospace,monospace);font-size:11px;line-height:1.6">` +
          `<strong>${esc(row.label)}</strong><br/>` +
          `${esc(metricLabel(metric))}: ${esc(metricFormat(row.value, metric))} ` +
          `(${esc(formatShare(row.share))} share)<br/>` +
          `Cost: ${esc(formatCost(row.cost))} &nbsp;&bull;&nbsp; ` +
          `Calls: ${esc(formatCalls(row.calls))} &nbsp;&bull;&nbsp; ` +
          `Tokens: ${esc(formatTokens(row.tokens))}` +
          `</div>`
        );
      },
    },
    plotOptions: {
      pie: {
        expandOnClick: false,
        donut: {
          size: '72%',
          labels: { show: false },
        },
      },
    },
  };

  const kicker = centerKickerPrefix
    ? `${centerKickerPrefix} ${metricLabel(metric)}`
    : metricLabel(metric);

  return (
    <div class="model-chart-panel">
      <div class="range-group" aria-label={`${id} metric`}>
        {metricOptions.map(m => (
          <button
            key={m}
            type="button"
            class={`range-btn${metric === m ? ' active' : ''}`}
            disabled={isMetricDisabled ? isMetricDisabled(m) : false}
            aria-pressed={metric === m}
            onClick={() => onMetricChange?.(m)}
          >
            {metricLabel(m)}
          </button>
        ))}
      </div>

      <div class="model-chart-ring">
        <ApexChart options={options} id={id} />
        <div class="model-chart-center" aria-hidden="true">
          <div class="model-chart-center-inner">
            <div class="model-chart-center-kicker">{kicker}</div>
            <div class="model-chart-center-total">{metricFormat(total, metric, true)}</div>
            {hasOther ? <div class="model-chart-center-meta">Top {TOP_N} + Other</div> : null}
          </div>
        </div>
      </div>

      {showLegend && (
        <div class="model-share-list">
          {donutRows.map(row => (
            <button
              key={row.label}
              type="button"
              class={`model-share-row${onSelectRow && !row.isOther ? ' interactive' : ''}`}
              onClick={onSelectRow && !row.isOther ? () => onSelectRow(row.label) : undefined}
              disabled={!onSelectRow || row.isOther}
              aria-label={row.isOther ? `${row.label} ${metricLabel(metric)} summary` : `Filter to ${row.label}`}
            >
              <div class="model-share-row-head">
                <div class="model-share-label">
                  <span class="model-share-swatch" style={{ background: row.color }} aria-hidden="true" />
                  <span title={row.label}>{row.label}</span>
                </div>
                <div class="model-share-value">{metricFormat(row.value, metric)}</div>
              </div>
              <div class="model-share-row-meta">
                <div class="model-share-bar" aria-label={`${row.label} ${metricLabel(metric)} share`}>
                  <div class="model-share-bar-fill" style={{ width: `${Math.min(100, row.share)}%`, background: row.color }} />
                </div>
                <div class="model-share-percent">{formatShare(row.share)}</div>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
