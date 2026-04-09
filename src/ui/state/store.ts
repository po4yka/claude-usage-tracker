import { signal } from '@preact/signals';
import type { DashboardData, RangeKey, SessionRow, ProjectAgg } from './types';

// Core data
export const rawData = signal<DashboardData | null>(null);

// Filter state
export const selectedModels = signal<Set<string>>(new Set());
export const selectedRange = signal<RangeKey>('30d');
export const projectSearchQuery = signal('');

// Pagination page size (used by SessionsTable via DataTable)
export const SESSIONS_PAGE_SIZE = 25;

// Cached results (updated by applyFilter)
export const lastFilteredSessions = signal<SessionRow[]>([]);
export const lastByProject = signal<ProjectAgg[]>([]);
