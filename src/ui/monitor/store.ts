import { signal } from '@preact/signals';
import type { LiveMonitorFocus, LiveMonitorResponse } from '../state/types';

export const liveMonitorData = signal<LiveMonitorResponse | null>(null);
export const liveMonitorFocus = signal<LiveMonitorFocus>('all');
export const liveMonitorRefreshing = signal<boolean>(false);
export const liveMonitorError = signal<string | null>(null);

export function setLiveMonitorData(data: LiveMonitorResponse): void {
  liveMonitorData.value = data;
  liveMonitorFocus.value = data.default_focus;
  liveMonitorError.value = null;
}
