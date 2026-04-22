import AppKit
import HeimdallDomain
import SwiftUI

struct AppShellView: View {
    @Bindable var shell: AppShellModel
    @Bindable var overview: OverviewFeatureModel
    let helperPort: Int
    let providerModel: (ProviderID) -> ProviderFeatureModel

    var body: some View {
        NavigationSplitView {
            WindowSidebar(shell: self.shell)
            .navigationTitle("HeimdallBar")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch self.shell.navigationSelection {
                    case .overview:
                        WindowOverviewView(
                            overview: self.overview,
                            shell: self.shell,
                            providerModel: self.providerModel
                        )
                    case .provider(let provider):
                        WindowProviderView(model: self.providerModel(provider))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task {
                        switch self.shell.navigationSelection {
                        case .overview:
                            await self.overview.refreshAll()
                        case .provider(let provider):
                            await self.providerModel(provider).refresh()
                        }
                    }
                }
                label: { Text("Refresh") }
                .help("Refresh the current view")
                .accessibilityLabel("Refresh the current view")
                .disabled(self.isBusy)

                SettingsLink {
                    Text("Settings")
                }
                .help("Open HeimdallBar settings")
                .accessibilityLabel("Open HeimdallBar settings")

                Button {
                    if let url = URL(string: "http://127.0.0.1:\(self.helperPort)") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Web Dashboard")
                }
                .help("Open the local Heimdall web dashboard")
                .accessibilityLabel("Open the local Heimdall web dashboard")
            }
        }
    }

    private var isBusy: Bool {
        switch self.shell.navigationSelection {
        case .overview:
            return self.overview.projection.isRefreshing
        case .provider(let provider):
            return self.providerModel(provider).isBusy
        }
    }
}

private struct WindowSidebar: View {
    @Bindable var shell: AppShellModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(self.shell.navigationItems, id: \.id) { item in
                    Button {
                        self.shell.selectNavigation(item)
                    } label: {
                        SidebarNavigationRow(
                            item: item,
                            isSelected: self.shell.navigationSelection == item
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .frame(minWidth: 228, idealWidth: 244, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct WindowOverviewView: View {
    @Bindable var overview: OverviewFeatureModel
    @Bindable var shell: AppShellModel
    let providerModel: (ProviderID) -> ProviderFeatureModel

    var body: some View {
        let projection = self.overview.projection

        VStack(alignment: .leading, spacing: 24) {
            WindowHeader(
                title: "Overview",
                subtitle: projection.refreshedAtLabel,
                issue: projection.globalIssueLabel,
                onRetry: {
                    Task { await self.overview.refreshAll() }
                },
                isRetrying: projection.isRefreshing
            )

            WindowOverviewProvidersSection(
                items: self.sortedItems(from: projection),
                providerModel: self.providerModel,
                openProvider: { provider in
                    self.shell.selectNavigation(.provider(provider))
                }
            )

            WindowOverviewActivitySection(projection: projection)
        }
    }

    private func sortedItems(from projection: OverviewMenuProjection) -> [ProviderMenuProjection] {
        projection.items.sorted {
            let lhs = self.severityRank(for: $0.visualState)
            let rhs = self.severityRank(for: $1.visualState)
            if lhs == rhs {
                return $0.title < $1.title
            }
            return lhs > rhs
        }
    }

    private func severityRank(for state: ProviderVisualState) -> Int {
        switch state {
        case .error: return 5
        case .incident: return 4
        case .degraded: return 3
        case .stale: return 2
        case .refreshing: return 1
        case .healthy: return 0
        }
    }
}

private struct WindowOverviewProvidersSection: View {
    let items: [ProviderMenuProjection]
    let providerModel: (ProviderID) -> ProviderFeatureModel
    let openProvider: (ProviderID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WindowSectionHeader(
                title: "Providers",
                subtitle: "Provider state, freshness, and current session quota"
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                ForEach(self.items) { item in
                    WindowOverviewProviderCard(
                        model: self.providerModel(item.provider),
                        item: item,
                        openProvider: {
                            self.openProvider(item.provider)
                        }
                    )
                }
            }
        }
    }
}

private struct WindowOverviewActivitySection: View {
    let projection: OverviewMenuProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WindowSectionHeader(
                title: "Activity",
                subtitle: "Combined usage and recent spend"
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                WindowOverviewTotalsCard(projection: self.projection)

                if !self.projection.historyFractions.isEmpty {
                    WindowOverviewHistoryCard(projection: self.projection)
                }
            }
        }
    }
}

private struct SidebarNavigationRow: View {
    let item: AppNavigationItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(self.isSelected ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: self.item.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(self.isSelected ? Color.primary : Color.secondary)
                        .symbolRenderingMode(.monochrome)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(self.item.title)
                    .font(.body.weight(self.isSelected ? .semibold : .medium))
                    .lineLimit(1)
                Text(self.item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(self.isSelected ? Color.primary.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    self.isSelected ? Color.primary.opacity(0.08) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WindowSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.title)
                .font(.title3.weight(.semibold))
            Text(self.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WindowOverviewHistoryCard: View {
    let projection: OverviewMenuProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 7 days")
                .font(.headline)
            Text("Relative daily spend normalized to the 7-day peak. Today appears at the right.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HistoryBarStrip(
                fractions: self.projection.historyFractions,
                showsHeader: false
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuCardBackground(opacity: 0.04, cornerRadius: 16)
    }
}

struct WindowProviderMetricSummary: Equatable {
    let title: String
    let value: String
    let qualifier: String
    let detail: String

    static func make(
        item: ProviderMenuProjection,
        showUsedValues: Bool
    ) -> Self {
        guard let lane = item.laneDetails.first,
              let remainingPercent = lane.remainingPercent else {
            return Self(
                title: "Session availability",
                value: "Unavailable",
                qualifier: "Live quota",
                detail: self.unavailableDetail(for: item)
            )
        }

        let shownPercent = showUsedValues
            ? max(0, min(100, 100 - remainingPercent))
            : remainingPercent

        return Self(
            title: showUsedValues ? "Session usage" : "Session remaining",
            value: "\(shownPercent)%",
            qualifier: showUsedValues ? "Used" : "Remaining",
            detail: lane.resetDetail ?? lane.summary
        )
    }

    private static func unavailableDetail(for item: ProviderMenuProjection) -> String {
        let sourceLabel = item.sourceLabel.lowercased()
        if item.isShowingCachedData {
            return "Showing last known provider data"
        }
        if sourceLabel.contains("oauth") {
            return "OAuth session data is unavailable"
        }
        if sourceLabel.contains("web") {
            return "Web session data is unavailable"
        }
        if sourceLabel.contains("cli") {
            return "CLI session data is unavailable"
        }
        return "Live session data is unavailable"
    }
}

private struct WindowOverviewProviderCard: View {
    @Bindable var model: ProviderFeatureModel
    let item: ProviderMenuProjection
    let openProvider: () -> Void

    private var metric: WindowProviderMetricSummary {
        WindowProviderMetricSummary.make(
            item: self.item,
            showUsedValues: self.model.showUsedValues
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(self.item.title)
                            .font(.title3.weight(.semibold))
                        StateBadge(state: self.item.visualState, label: self.item.stateLabel)
                    }

                    Text(self.item.costLabel)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text(self.item.lastRefreshLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Button("Open", action: self.openProvider)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.metric.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(self.metric.detail)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let secondaryLine = self.secondaryLine {
                        WindowCardNote(
                            text: secondaryLine,
                            tone: self.secondaryLineTone
                        )
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(self.metric.value)
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                    Text(self.metric.qualifier)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuCardBackground(opacity: 0.04, cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(self.borderColor, lineWidth: self.borderLineWidth)
        )
    }

    private var secondaryLine: String? {
        if let incidentLabel = self.item.incidentLabel {
            return incidentLabel
        }
        if let warning = self.item.warningLabels.first {
            return warning
        }
        return self.item.authHeadline
    }

    private var secondaryLineTone: WindowCardNote.Tone {
        if self.item.incidentLabel != nil {
            return .critical
        }
        if !self.item.warningLabels.isEmpty {
            return .warning
        }
        return .neutral
    }

    private var borderColor: Color {
        switch self.item.visualState {
        case .error:
            return .red.opacity(0.35)
        case .incident:
            return .red.opacity(0.28)
        case .degraded, .stale:
            return .orange.opacity(0.3)
        case .refreshing:
            return Color.primary.opacity(0.14)
        case .healthy:
            return Color.primary.opacity(0.08)
        }
    }

    private var borderLineWidth: CGFloat {
        switch self.item.visualState {
        case .healthy:
            return 1
        default:
            return 1.5
        }
    }
}

private struct WindowOverviewTotalsCard: View {
    let projection: OverviewMenuProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.headline)

            Text(self.combinedValue)
                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())

            if let topProvider = self.topProvider {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Highest spend: \(topProvider.title)")
                        .font(.callout.weight(.medium))
                    StateBadge(state: topProvider.visualState, label: topProvider.stateLabel)
                }
            } else {
                Text("Waiting for provider activity")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text(self.projection.refreshedAtLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(self.projection.activitySummaryLabel)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuCardBackground(opacity: 0.04, cornerRadius: 16)
    }

    private var combinedValue: String {
        guard let value = self.projection.combinedCostLabel.split(separator: ":").last else {
            return self.projection.combinedCostLabel
        }
        return value.trimmingCharacters(in: .whitespaces)
    }

    private var topProvider: ProviderMenuProjection? {
        self.projection.items.max { lhs, rhs in
            Self.todayCost(lhs) < Self.todayCost(rhs)
        }
    }

    private static func todayCost(_ item: ProviderMenuProjection) -> Double {
        guard let value = item.costLabel.split(separator: "·").first?
            .replacingOccurrences(of: "Today: $", with: "")
            .trimmingCharacters(in: .whitespaces) else {
            return 0
        }
        return Double(value) ?? 0
    }
}

private struct WindowProviderView: View {
    @Bindable var model: ProviderFeatureModel

    /// If we have a weekly projection, append it to the refresh-status line
    /// so the user sees the pace at a glance on every provider page.
    static func headerSubtitle(_ projection: ProviderMenuProjection) -> String {
        let status = projection.refreshStatusLabel
        guard let projected = projection.weeklyProjectedCostUSD, projected > 0 else {
            return status
        }
        let formatted: String
        if projected >= 1000 {
            formatted = String(format: "$%.0f", projected)
        } else if projected >= 10 {
            formatted = String(format: "$%.1f", projected)
        } else {
            formatted = String(format: "$%.2f", projected)
        }
        return "\(status) · Weekly projected \(formatted)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            WindowHeader(
                title: self.model.provider.title,
                subtitle: Self.headerSubtitle(self.model.projection),
                issue: self.model.issue?.message ?? self.model.projection.globalIssueLabel,
                onRetry: {
                    Task { await self.model.refresh() }
                },
                isRetrying: self.model.isBusy
            )

            ProviderMenuCard(providerModel: self.model)

            ProviderSessionDetails(model: self.model)
        }
    }
}

private struct WindowHeader: View {
    let title: String
    let subtitle: String
    let issue: String?
    var onRetry: (() -> Void)? = nil
    var isRetrying: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.title)
                .font(.system(size: 24, weight: .semibold))
            Text(self.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
            if let issue, !issue.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Text(issue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if let onRetry {
                        Button(self.isRetrying ? "Retrying…" : "Retry", action: onRetry)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(self.isRetrying)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
    }
}

private struct WindowCardNote: View {
    enum Tone {
        case neutral
        case warning
        case critical
    }

    let text: String
    let tone: Tone

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: self.iconName)
                .font(.caption.weight(.semibold))
            Text(self.text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(self.color)
    }

    private var iconName: String {
        switch self.tone {
        case .neutral:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }

    private var color: Color {
        switch self.tone {
        case .neutral:
            return .secondary
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

private struct ProviderSessionDetails: View {
    @Bindable var model: ProviderFeatureModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Web Session")
                .font(.headline)
            if let session = self.model.importedSession {
                Text(session.expired ? "Stored session is expired." : (session.loginRequired ? "Stored session is missing an active auth cookie." : "Stored session is ready."))
                Text("Source: \(session.browserSource.title) · \(session.profileName)")
                    .foregroundStyle(.secondary)
                Button("Reset Session") {
                    Task { await self.model.resetBrowserSession() }
                }
                .disabled(self.model.isImportingSession)
            } else {
                Text("No imported browser session stored.")
                    .foregroundStyle(.secondary)
            }

            ForEach(self.model.importCandidates) { candidate in
                Button("Import from \(candidate.title)") {
                    Task { await self.model.importBrowserSession(candidate: candidate) }
                }
                .disabled(self.model.isImportingSession)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.03)))
    }
}
