import { activeDashboardTab, type DashboardTab } from '../state/store';

const TABS: Array<{ key: DashboardTab; label: string; summary: string }> = [
  { key: 'overview', label: 'Overview', summary: 'status, spend, sync' },
  { key: 'activity', label: 'Activity', summary: 'charts & timing' },
  { key: 'breakdowns', label: 'Breakdowns', summary: 'tools, branches, versions' },
  { key: 'tables', label: 'Tables', summary: 'sessions, models, projects' },
];

interface DashboardTabsProps {
  onTabChange: (tab: DashboardTab) => void;
}

export function DashboardTabs({ onTabChange }: DashboardTabsProps) {
  return (
    <nav id="dashboard-tabs" aria-label="Dashboard sections">
      {TABS.map(tab => {
        const active = activeDashboardTab.value === tab.key;
        return (
          <button
            key={tab.key}
            type="button"
            class={`dashboard-tab${active ? ' active' : ''}`}
            aria-pressed={active}
            onClick={() => onTabChange(tab.key)}
          >
            <span class="dashboard-tab-label">{tab.label}</span>
            <span class="dashboard-tab-summary">{tab.summary}</span>
          </button>
        );
      })}
    </nav>
  );
}
