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
    func windowOverviewProviderCostInsightsExposeTokenCountsCacheRatesAndMix() {
        let model = WindowOverviewProviderCostInsightsModel.make(item: self.makeProjection(
            laneDetails: [],
            todayCostUSD: 172.77,
            last30DaysCostUSD: 14_708.15,
            todayBreakdown: TokenBreakdown(
                input: 1_200_000,
                output: 320_000,
                cacheRead: 8_400_000,
                cacheCreation: 150_000,
                reasoningOutput: 80_000
            ),
            last30DaysBreakdown: TokenBreakdown(
                input: 48_000_000,
                output: 21_000_000,
                cacheRead: 330_000_000,
                cacheCreation: 9_000_000,
                reasoningOutput: 1_800_000
            ),
            cacheHitRateToday: 0.731,
            cacheHitRate30d: 0.684,
            cacheSavings30dUSD: 1824.0
        ))

        #expect(model.stats == [
            .init(title: "Today tokens", value: "10.2M", detail: "$172.77"),
            .init(title: "30-day tokens", value: "409.8M", detail: "$14,708.15"),
            .init(title: "Cache hit rate", value: "73.1%", detail: "30-day avg 68.4%"),
            .init(title: "Cache savings", value: "$1,824.00", detail: "Last 30 days"),
        ])
        #expect(model.mixLabel == "Today mix: 1.2M in · 320.0K out · 8.4M cache read · 150.0K cache write · 80.0K reasoning")
    }

    @Test
    func windowOverviewProviderCostInsightsFallBackToThirtyDaySignalsWhenTodayMissing() {
        let model = WindowOverviewProviderCostInsightsModel.make(item: self.makeProjection(
            laneDetails: [],
            todayBreakdown: nil,
            last30DaysBreakdown: TokenBreakdown(
                input: 0,
                output: 0,
                cacheRead: 900_000,
                cacheCreation: 120_000,
                reasoningOutput: 0
            ),
            cacheHitRateToday: nil,
            cacheHitRate30d: 0.882,
            cacheSavings30dUSD: nil
        ))

        #expect(model.stats == [
            .init(title: "30-day tokens", value: "1.0M", detail: "$42.00"),
            .init(title: "Cache hit rate", value: "88.2%", detail: "Last 30 days"),
        ])
        #expect(model.mixLabel == "30-day mix: 900.0K cache read · 120.0K cache write")
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
        incidentLabel: String? = nil,
        todayCostUSD: Double = 6.8,
        last30DaysCostUSD: Double = 42,
        todayBreakdown: TokenBreakdown? = TokenBreakdown(input: 12_000, output: 8_000, cacheRead: 44_000),
        last30DaysBreakdown: TokenBreakdown? = TokenBreakdown(input: 90_000, output: 44_000, cacheRead: 210_000),
        cacheHitRateToday: Double? = 0.54,
        cacheHitRate30d: Double? = 0.49,
        cacheSavings30dUSD: Double? = 18.25
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
            todayCostUSD: todayCostUSD,
            last30DaysCostUSD: last30DaysCostUSD,
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
            adjunct: nil,
            todayBreakdown: todayBreakdown,
            last30DaysBreakdown: last30DaysBreakdown,
            cacheHitRateToday: cacheHitRateToday,
            cacheHitRate30d: cacheHitRate30d,
            cacheSavings30dUSD: cacheSavings30dUSD
        )
    }
}
