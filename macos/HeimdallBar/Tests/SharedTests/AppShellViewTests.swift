import Foundation
import Testing
import HeimdallDomain
@testable import HeimdallAppUI

struct AppShellViewTests {
    @Test
    func windowProviderMetricSummaryUsesLeftQualifierForRemainingMode() {
        let summary = WindowProviderMetricSummary.make(
            item: self.makeProjection(
                laneDetails: [
                    LaneDetailProjection(
                        title: "Session",
                        summary: "64% left",
                        remainingPercent: 64,
                        resetDetail: "resets in 18m",
                        paceLabel: "Stable"
                    )
                ]
            ),
            showUsedValues: false
        )

        #expect(summary == WindowProviderMetricSummary(
            title: "Session remaining",
            value: "64%",
            qualifier: "Remaining",
            detail: "resets in 18m"
        ))
    }

    @Test
    func windowProviderMetricSummaryUsesUsedQualifierForUsedMode() {
        let summary = WindowProviderMetricSummary.make(
            item: self.makeProjection(
                laneDetails: [
                    LaneDetailProjection(
                        title: "Session",
                        summary: "64% left",
                        remainingPercent: 64,
                        resetDetail: "resets in 18m",
                        paceLabel: "Stable"
                    )
                ]
            ),
            showUsedValues: true
        )

        #expect(summary == WindowProviderMetricSummary(
            title: "Session usage",
            value: "36%",
            qualifier: "Used",
            detail: "resets in 18m"
        ))
    }

    @Test
    func windowProviderMetricSummaryUsesUnavailableLabelWhenQuotaIsMissing() {
        let summary = WindowProviderMetricSummary.make(
            item: self.makeProjection(
                laneDetails: [],
                sourceLabel: "Source: oauth"
            ),
            showUsedValues: false
        )

        #expect(summary == WindowProviderMetricSummary(
            title: "Session availability",
            value: "Unavailable",
            qualifier: "Live quota",
            detail: "OAuth session data is unavailable"
        ))
    }

    @Test
    func windowProviderMetricSummaryUsesCachedDataDetailWhenQuotaIsMissing() {
        let summary = WindowProviderMetricSummary.make(
            item: self.makeProjection(
                laneDetails: [],
                sourceLabel: "Source: cli",
                isShowingCachedData: true
            ),
            showUsedValues: false
        )

        #expect(summary.detail == "Showing last known provider data")
    }

    @Test
    func windowProviderMetricSummaryKeepsSourceSpecificUnavailableDetail() {
        let webSummary = WindowProviderMetricSummary.make(
            item: self.makeProjection(
                laneDetails: [],
                sourceLabel: "Source: web"
            ),
            showUsedValues: false
        )
        let cliSummary = WindowProviderMetricSummary.make(
            item: self.makeProjection(
                laneDetails: [],
                sourceLabel: "Source: cli"
            ),
            showUsedValues: false
        )

        #expect(webSummary.detail == "Web session data is unavailable")
        #expect(cliSummary.detail == "CLI session data is unavailable")
    }

    @Test
    func windowOverviewProviderNotePrioritizesIncidentWarningAndAuthSignals() {
        let incident = WindowOverviewProviderNote.make(item: self.makeProjection(
            laneDetails: [],
            authHeadline: "Authentication needs attention",
            warningLabels: ["Quota refresh failed"],
            incidentLabel: "[CRITICAL] OpenAI incident"
        ))
        let warning = WindowOverviewProviderNote.make(item: self.makeProjection(
            laneDetails: [],
            authHeadline: "Authentication needs attention",
            warningLabels: ["Quota refresh failed"]
        ))
        let authOnly = WindowOverviewProviderNote.make(item: self.makeProjection(
            laneDetails: [],
            authHeadline: "Authentication needs attention"
        ))

        #expect(incident == WindowOverviewProviderNote(text: "[CRITICAL] OpenAI incident", tone: .critical))
        #expect(warning == WindowOverviewProviderNote(text: "Quota refresh failed", tone: .warning))
        #expect(authOnly == WindowOverviewProviderNote(text: "Authentication needs attention", tone: .neutral))
    }

    @Test
    func providerStateBadgeDescriptorUsesIconsInsteadOfColorOnlyCues() {
        #expect(ProviderStateBadgeDescriptor.make(state: .healthy).symbolName == "checkmark.circle.fill")
        #expect(ProviderStateBadgeDescriptor.make(state: .degraded).symbolName == "exclamationmark.triangle.fill")
        #expect(ProviderStateBadgeDescriptor.make(state: .incident).symbolName == "exclamationmark.octagon.fill")
        #expect(ProviderStateBadgeDescriptor.make(state: .error).symbolName == "xmark.octagon.fill")
    }

    @Test
    func sessionHealthDescriptorAddsTextualStatusIcons() {
        #expect(SessionHealthDescriptor.make(subtitle: "Connected").systemImage == "checkmark.circle.fill")
        #expect(SessionHealthDescriptor.make(subtitle: "Expired").systemImage == "exclamationmark.triangle.fill")
        #expect(SessionHealthDescriptor.make(subtitle: "Missing").systemImage == "circle.dashed")
    }

    private func makeProjection(
        laneDetails: [LaneDetailProjection],
        sourceLabel: String = "Source: cli",
        isShowingCachedData: Bool = false,
        authHeadline: String? = nil,
        warningLabels: [String] = [],
        incidentLabel: String? = nil
    ) -> ProviderMenuProjection {
        ProviderMenuProjection(
            provider: .codex,
            title: "Codex",
            sourceLabel: sourceLabel,
            sourceExplanationLabel: nil,
            authHeadline: authHeadline,
            authDetail: nil,
            authDiagnosticCode: nil,
            authSummaryLabel: nil,
            authRecoveryActions: [],
            warningLabels: warningLabels,
            visualState: .healthy,
            stateLabel: "Operational",
            statusLabel: nil,
            identityLabel: nil,
            lastRefreshLabel: "Last refresh: 2m ago",
            refreshStatusLabel: "Last refresh: 2m ago",
            costLabel: "Today: $6.80 · 30 days: $42.00",
            todayCostUSD: 6.8,
            last30DaysCostUSD: 42,
            laneDetails: laneDetails,
            creditsLabel: nil,
            incidentLabel: incidentLabel,
            stale: false,
            isShowingCachedData: isShowingCachedData,
            isRefreshing: false,
            error: nil,
            globalIssueLabel: nil,
            historyFractions: [],
            claudeFactors: [],
            adjunct: nil
        )
    }
}
