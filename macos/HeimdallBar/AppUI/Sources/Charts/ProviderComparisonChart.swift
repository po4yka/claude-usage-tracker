import Charts
import HeimdallDomain
import SwiftUI

/// Stacked-area chart showing per-provider daily cost over the trailing 30
/// days. Each provider in `items` that has parseable `dailyCosts` data becomes
/// one area series. The first provider uses `Color.accentColor`; remaining
/// providers step down the monochrome `Color.primary` opacity ladder.
struct ProviderComparisonChart: View {
    let items: [ProviderMenuProjection]

    struct Entry: Identifiable, Hashable {
        let day: Date
        let providerTitle: String
        let costUSD: Double
        var id: String { "\(self.day.timeIntervalSince1970)-\(self.providerTitle)" }
    }

    var body: some View {
        let entries = Self.entries(from: self.items)
        let providerTitles = Self.providerTitles(from: self.items)
        let hasData = providerTitles.count >= 2 && !entries.isEmpty
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Provider split, 30 days",
                caption: "Stacked daily cost by provider.",
                trailing: hasData ? AnyView(ProviderComparisonLegend(titles: providerTitles)) : nil
            )
            if hasData {
                self.chart(entries: entries, providerTitles: providerTitles)
                    .frame(height: 72)
            } else {
                Text("No provider activity yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
        .padding(8)
        .menuCardBackground(
            opacity: ChartStyle.cardBackgroundOpacity,
            cornerRadius: ChartStyle.cardCornerRadius
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Provider cost split, last 30 days")
    }

    private func chart(entries: [Entry], providerTitles: [String]) -> some View {
        Chart(entries) { entry in
            AreaMark(
                x: .value("Day", entry.day),
                y: .value("Cost", entry.costUSD),
                stacking: .standard
            )
            .foregroundStyle(by: .value("Provider", entry.providerTitle))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(
            domain: providerTitles,
            range: Self.providerScale(count: providerTitles.count)
        )
        .chartLegend(.hidden)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(Self.axisFormatter.string(from: date))
                            .font(.system(size: 9).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.primary.opacity(0.15))
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .animation(ChartStyle.animation, value: entries)
    }

    // MARK: - Data transform

    nonisolated static func entries(from items: [ProviderMenuProjection]) -> [Entry] {
        var result: [Entry] = []
        for item in items {
            let parsed = item.dailyCosts.compactMap { point -> Entry? in
                guard let date = Self.dayFormatter.date(from: point.day) else { return nil }
                return Entry(day: date, providerTitle: item.title, costUSD: point.costUSD)
            }
            result.append(contentsOf: parsed)
        }
        return result.sorted { $0.day < $1.day }
    }

    nonisolated static func providerTitles(from items: [ProviderMenuProjection]) -> [String] {
        items.filter { item in
            item.dailyCosts.contains { Self.dayFormatter.date(from: $0.day) != nil }
        }.map(\.title)
    }

    /// Monochrome opacity ladder: first provider uses `accentColor`, rest step
    /// down `Color.primary` at 0.72 / 0.45 / 0.24, cycling when count > 4.
    nonisolated static func providerScale(count: Int) -> [Color] {
        let ladder: [Color] = [
            Color.primary.opacity(0.72),
            Color.primary.opacity(0.45),
            Color.primary.opacity(0.24),
        ]
        guard count > 0 else { return [] }
        var result: [Color] = [Color.accentColor]
        for i in 1..<count {
            result.append(ladder[(i - 1) % ladder.count])
        }
        return result
    }

    nonisolated(unsafe) static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    nonisolated(unsafe) private static let axisFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}

// MARK: - Inline legend

/// Compact inline legend: one dot + sentence-case label per provider title.
/// Mirrors the shape of `TokenCategoryLegend` from ChartStyle.swift.
struct ProviderComparisonLegend: View {
    let titles: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(self.titles.enumerated()), id: \.offset) { index, title in
                HStack(spacing: 3) {
                    Circle()
                        .fill(ProviderComparisonChart.providerScale(count: self.titles.count)[index])
                        .frame(width: 6, height: 6)
                    Text(title)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Provider split — 30 days") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    let base = Date()
    let calendar = Calendar.current

    func makeProjection(title: String, providerID: ProviderID, scale: Double) -> ProviderMenuProjection {
        let points: [CostHistoryPoint] = (0..<30).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: base) ?? base
            let ramp = Double(30 - offset) / 30.0
            let plateau = min(ramp * 1.4, 1.0)
            let cost = scale * (1.5 + plateau * 12.0 + Double(offset % 3) * 0.8)
            return CostHistoryPoint(day: formatter.string(from: date), totalTokens: 0, costUSD: cost)
        }
        return ProviderMenuProjection(
            provider: providerID,
            title: title,
            sourceLabel: "",
            sourceExplanationLabel: nil,
            authHeadline: nil,
            authDetail: nil,
            authDiagnosticCode: nil,
            authSummaryLabel: nil,
            authRecoveryActions: [],
            warningLabels: [],
            visualState: .healthy,
            stateLabel: "",
            statusLabel: nil,
            identityLabel: nil,
            lastRefreshLabel: "",
            refreshStatusLabel: "",
            costLabel: "",
            laneDetails: [],
            creditsLabel: nil,
            incidentLabel: nil,
            stale: false,
            isShowingCachedData: false,
            isRefreshing: false,
            error: nil,
            globalIssueLabel: nil,
            historyFractions: [],
            claudeFactors: [],
            adjunct: nil,
            dailyCosts: points
        )
    }

    let items = [
        makeProjection(title: "Claude", providerID: .claude, scale: 1.0),
        makeProjection(title: "Codex", providerID: .codex, scale: 0.45),
    ]
    return ProviderComparisonChart(items: items)
        .padding()
        .frame(width: 360)
}
