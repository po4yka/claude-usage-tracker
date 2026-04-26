import { useState } from 'preact/hooks';
import { MetricDonut } from './MetricDonut';
import { fmtCost, fmtCostCompact, fmt } from '../../lib/format';
import type { ModelAgg } from '../../state/types';

type ModelMetric = 'cost' | 'tokens' | 'calls';

const METRIC_LABELS: Record<ModelMetric, string> = {
  cost: 'Cost',
  tokens: 'Tokens',
  calls: 'Calls',
};

const METRIC_OPTIONS: ModelMetric[] = ['cost', 'tokens', 'calls'];

function totalTokens(row: ModelAgg): number {
  return row.input + row.output + row.cache_read + row.cache_creation + row.reasoning_output;
}

function getMetricValue(row: ModelAgg, metric: ModelMetric): number {
  switch (metric) {
    case 'cost': return row.cost;
    case 'tokens': return totalTokens(row);
    case 'calls': return row.turns;
  }
}

function formatMetricValue(value: number, metric: ModelMetric, large = false): string {
  switch (metric) {
    case 'cost': return large ? fmtCostCompact(value) : fmtCost(value);
    case 'tokens':
    case 'calls': return fmt(value);
  }
}

export function ModelChart({
  byModel,
  onSelectModel,
}: {
  byModel: ModelAgg[];
  onSelectModel?: (model: string) => void;
}) {
  if (!byModel.length) return null;

  const [selectedMetric, setSelectedMetric] = useState<ModelMetric>('cost');

  const totals: Record<ModelMetric, number> = {
    cost: byModel.reduce((sum, row) => sum + row.cost, 0),
    tokens: byModel.reduce((sum, row) => sum + totalTokens(row), 0),
    calls: byModel.reduce((sum, row) => sum + row.turns, 0),
  };
  const enabledMetrics = METRIC_OPTIONS.filter(metric => totals[metric] > 0);
  const metric = enabledMetrics.includes(selectedMetric) ? selectedMetric : (enabledMetrics[0] ?? 'cost');

  return MetricDonut<ModelAgg, ModelMetric>({
    rows: byModel,
    metric,
    metricOptions: METRIC_OPTIONS,
    metricLabel: m => METRIC_LABELS[m],
    metricValue: getMetricValue,
    metricFormat: formatMetricValue,
    rowLabel: row => row.model,
    rowCost: row => row.cost,
    rowCalls: row => row.turns,
    rowTokens: totalTokens,
    id: 'chart-model-apex',
    onMetricChange: setSelectedMetric,
    isMetricDisabled: m => totals[m] <= 0,
    showLegend: true,
    onSelectRow: onSelectModel,
    onSliceClick: onSelectModel,
    formatCost: v => fmtCost(v),
    formatCalls: v => fmt(v),
    formatTokens: v => fmt(v),
  });
}
