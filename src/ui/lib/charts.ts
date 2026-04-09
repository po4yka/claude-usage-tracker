import type { RangeKey } from '../state/types';

// ── Chart colors ───────────────────────────────────────────────────────
export const TOKEN_COLORS: Record<string, string> = {
  input:          'rgba(79,142,247,0.8)',
  output:         'rgba(167,139,250,0.8)',
  cache_read:     'rgba(74,222,128,0.6)',
  cache_creation: 'rgba(251,191,36,0.6)',
};
export const MODEL_COLORS = ['#d97757', '#4f8ef7', '#4ade80', '#a78bfa', '#fbbf24', '#f472b6', '#34d399', '#60a5fa'];

// ── Time range ─────────────────────────────────────────────────────────
export const RANGE_LABELS: Record<RangeKey, string> = {
  '7d': 'Last 7 Days', '30d': 'Last 30 Days', '90d': 'Last 90 Days', 'all': 'All Time',
};
export const RANGE_TICKS: Record<RangeKey, number> = { '7d': 7, '30d': 15, '90d': 13, 'all': 12 };

// ── ApexCharts theme helper ───────────────────────────────────────────
export function apexThemeMode(): 'light' | 'dark' {
  return document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
}

export function cssVar(name: string): string {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}
