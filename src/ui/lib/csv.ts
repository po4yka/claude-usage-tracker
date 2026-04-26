// ── CSV Export Utilities ───────────────────────────────────────────────

export function csvField(val: unknown): string {
  const s = String(val);
  // Prevent CSV injection (formula execution in spreadsheets)
  const needsPrefix = /^[=+\-@\t\r]/.test(s);
  const escaped = needsPrefix ? "'" + s : s;
  if (escaped.includes(',') || escaped.includes('"') || escaped.includes('\n')) {
    return '"' + escaped.replace(/"/g, '""') + '"';
  }
  return escaped;
}

export function csvTimestamp(): string {
  // UTC for export filenames so the same export produces the same filename
  // across timezones (and so the test is TZ-stable).
  const d = new Date();
  return d.getUTCFullYear() + '-' + String(d.getUTCMonth() + 1).padStart(2, '0') + '-' + String(d.getUTCDate()).padStart(2, '0')
    + '_' + String(d.getUTCHours()).padStart(2, '0') + String(d.getUTCMinutes()).padStart(2, '0');
}

export function downloadCSV(reportType: string, header: string[], rows: unknown[][]): void {
  const lines = [header.map(csvField).join(',')];
  for (const row of rows) lines.push(row.map(csvField).join(','));
  const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = reportType + '_' + csvTimestamp() + '.csv';
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
