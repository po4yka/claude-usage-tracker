export function $(id: string): HTMLElement {
  return document.getElementById(id)!;
}

export function fmt(n: number): string {
  if (n >= 1e9) return (n / 1e9).toFixed(2) + 'B';
  if (n >= 1e6) return (n / 1e6).toFixed(2) + 'M';
  if (n >= 1e3) return (n / 1e3).toFixed(1) + 'K';
  return n.toLocaleString();
}

export function fmtCost(c: number): string {
  return '$' + c.toFixed(4);
}

export function fmtCostBig(c: number): string {
  return '$' + c.toFixed(2);
}

export function fmtResetTime(minutes: number | null | undefined): string {
  if (minutes == null || minutes <= 0) return 'now';
  if (minutes >= 1440) return Math.floor(minutes / 1440) + 'd ' + Math.floor((minutes % 1440) / 60) + 'h';
  if (minutes >= 60) return Math.floor(minutes / 60) + 'h ' + (minutes % 60) + 'm';
  return minutes + 'm';
}

export function progressColor(percent: number): string {
  if (percent >= 90) return 'var(--accent)';
  if (percent >= 70) return 'var(--warning)';
  return 'var(--success)';
}

/** Phase 12: returns true when at least one row has a non-null credits value. */
export function anyHasCredits(rows: Array<{ credits?: number | null }>): boolean {
  return rows.some(r => r.credits != null);
}

/** Phase 12: formats an Amp credits value; returns em-dash for null/undefined. */
export function fmtCredits(n: number | null | undefined): string {
  if (n == null) return '\u2014';
  return n.toFixed(2);
}
