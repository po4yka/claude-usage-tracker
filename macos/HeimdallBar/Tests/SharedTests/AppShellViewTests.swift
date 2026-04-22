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
    func windowOverviewQuotaWindowsExposeSessionAndWeeklyRemainingState() {
        let model = WindowOverviewQuotaWindowsModel.make(item: self.makeProjection(
            laneDetails: [
                LaneDetailProjection(
                    title: "Session",
                    summary: "Session: 98% left · pace stable · resets in 3h 59m",
                    remainingPercent: 98,
                    resetDetail: "resets in 3h 59m",
                    paceLabel: "Stable",
                    resetMinutes: 239,
                    windowMinutes: 300
                ),
                LaneDetailProjection(
                    title: "Weekly",
                    summary: "Weekly: 81% left · pace stable · resets in 4d 2h",
                    remainingPercent: 81,
                    resetDetail: "resets in 4d 2h",
                    paceLabel: "Stable",
                    resetMinutes: 5_880,
                    windowMinutes: 10_080
                ),
            ]
        ))

        #expect(model.lanes.map(\.title) == ["Session", "Weekly"])
        #expect(model.primary?.remainingLabel == "98%")
        #expect(model.secondary?.remainingLabel == "81%")
        #expect(model.primary?.elapsedFraction == 0.20333333333333337)
        #expect(model.secondary?.elapsedFraction == 0.41666666666666663)
    }

    @Test
    func windowOverviewQuotaWindowsSkipUnavailableWindowsAndMissingTiming() {
        let model = WindowOverviewQuotaWindowsModel.make(item: self.makeProjection(
            laneDetails: [
                LaneDetailProjection(
                    title: "Session",
                    summary: "Session: unavailable",
                    remainingPercent: nil,
                    resetDetail: nil,
                    paceLabel: nil
                ),
                LaneDetailProjection(
                    title: "Weekly",
                    summary: "Weekly: 72% left",
                    remainingPercent: 72,
                    resetDetail: "resets in 3d",
                    paceLabel: "Stable",
                    resetMinutes: nil,
                    windowMinutes: 10_080
                ),
            ]
        ))

        #expect(model.lanes.count == 1)
        #expect(model.primary?.title == "Weekly")
        #expect(model.chartLanes.isEmpty)
    }

    @Test
    func windowOverviewHistorySummaryHighlightsPeakTodayAndActiveDays() {
        let model = WindowOverviewHistorySummaryModel.make(fractions: [0.22, 0.0, 0.58, 0.11, 1.0, 0.34, 0.17])

        #expect(model?.peakLabel == "Mon 100%")
        #expect(model?.todayLabel == "17%")
        #expect(model?.activeDaysLabel == "6/7")
    }

    @Test
    func windowOverviewHistorySummaryPrefersTheFirstPeakWhenFractionsTie() {
        let model = WindowOverviewHistorySummaryModel.make(fractions: [0.12, 1.0, 0.48, 1.0, 0.03, 0.0, 0.2])

        #expect(model?.peakLabel == "Fri 100%")
        #expect(model?.todayLabel == "20%")
        #expect(model?.activeDaysLabel == "5/7")
    }

    @Test
    func windowOverviewQuotaWindowsKeepOnlyThePrimaryTwoLanes() {
        let model = WindowOverviewQuotaWindowsModel.make(item: self.makeProjection(
            laneDetails: [
                LaneDetailProjection(
                    title: "Session",
                    summary: "Session: 94% left",
                    remainingPercent: 94,
                    resetDetail: "resets in 4h",
                    paceLabel: "Comfortable",
                    resetMinutes: 240,
                    windowMinutes: 300
                ),
                LaneDetailProjection(
                    title: "Weekly",
                    summary: "Weekly: 12% left",
                    remainingPercent: 12,
                    resetDetail: "resets in 1d 6h",
                    paceLabel: "Critical",
                    resetMinutes: 1_800,
                    windowMinutes: 10_080
                ),
                LaneDetailProjection(
                    title: "Monthly",
                    summary: "Monthly: 88% left",
                    remainingPercent: 88,
                    resetDetail: "resets in 12d",
                    paceLabel: "Stable",
                    resetMinutes: 17_280,
                    windowMinutes: 43_200
                ),
            ]
        ))

        #expect(model.lanes.map(\.title) == ["Session", "Weekly"])
        #expect(model.secondary?.remainingLabel == "12%")
    }

    @Test
    func windowOverviewQuotaWindowsClampElapsedFractionToBounds() {
        let model = WindowOverviewQuotaWindowsModel.make(item: self.makeProjection(
            laneDetails: [
                LaneDetailProjection(
                    title: "Session",
                    summary: "Session: 91% left",
                    remainingPercent: 91,
                    resetDetail: "resets in 6h",
                    paceLabel: "Stable",
                    resetMinutes: 360,
                    windowMinutes: 300
                ),
                LaneDetailProjection(
                    title: "Weekly",
                    summary: "Weekly: 63% left",
                    remainingPercent: 63,
                    resetDetail: "resets now",
                    paceLabel: "Comfortable",
                    resetMinutes: 0,
                    windowMinutes: 10_080
                ),
            ]
        ))

        #expect(model.primary?.elapsedFraction == 0)
        #expect(model.secondary?.elapsedFraction == 1)
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
            historyBreakdowns: [],
            todayBreakdown: todayBreakdown,
            last30DaysBreakdown: last30DaysBreakdown,
            cacheHitRateToday: cacheHitRateToday,
            cacheHitRate30d: cacheHitRate30d,
            cacheSavings30dUSD: cacheSavings30dUSD,
            weeklyProjectedCostUSD: nil,
            spendTrendDirection: nil,
            dailyCosts: [],
            byModel: [],
            byProject: [],
            byTool: [],
            byMcp: [],
            hourlyActivity: [],
            activityHeatmap: [],
            recentSessions: [],
            subagentBreakdown: nil,
            versionBreakdown: []
        )
    }
}
