import Charts
import HeimdallDomain
import SwiftUI

/// 7-day (or N-day) stacked bars, one stack per day, colored by token
/// category. Replaces the hand-rolled `StackedDayBar`. Layout matches
/// `HistoryBarChart` so the two can swap places based on whether the
/// underlying snapshot has category breakdowns available.
struct TokenStackChart: View {
    let breakdowns: [TokenBreakdown]
    var showsHeader: Bool = true
    @State private var selectedDayIndex: Int?

    struct Entry: Identifiable, Hashable {
        let dayIndex: Int
        let dayLabel: String
        let category: TokenCategory
        let tokens: Int

        var id: String { "\(self.dayIndex)-\(self.category.label)" }
    }

    struct Summary: Equatable {
        let totalTokens: Int
        let averageDailyTokens: Int
        let peakDayIndex: Int
        let peakDayTotal: Int
        let todayTotal: Int
    }

    var body: some View {
        let entries = Self.entries(from: self.breakdowns)
        let summary = Self.summary(from: self.breakdowns)
        VStack(alignment: .leading, spacing: 6) {
            if self.showsHeader {
                ChartHeader(
                    title: "Usage history",
                    caption: "Absolute daily token totals with per-category mix."
                )
            }
            if !entries.isEmpty, let summary {
                self.summaryRow(summary)
                self.chart(entries: entries, summary: summary)
                    .frame(height: 76)
                    .help(Self.tooltip(for: self.breakdowns))
            } else {
                Text("No token breakdown yet.")
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
        .accessibilityLabel("Usage history by category, last \(self.breakdowns.count) days")
    }

    private func chart(entries: [Entry], summary: Summary) -> some View {
        let labels = Self.dayLabels(count: self.breakdowns.count)
        let selectedBreakdown = self.selectedDayIndex.flatMap { index -> (Int, TokenBreakdown)? in
            guard self.breakdowns.indices.contains(index) else { return nil }
            return (index, self.breakdowns[index])
        }
        let yAxisMarks = Self.yAxisMarks(maxTotal: summary.peakDayTotal)
        return Chart {
            ForEach(entries) { entry in
                BarMark(
                    x: .value("Day", entry.dayIndex),
                    y: .value("Tokens", entry.tokens)
                )
                .foregroundStyle(by: .value("Category", entry.category.label))
                .opacity(self.selectedDayIndex == nil || self.selectedDayIndex == entry.dayIndex ? 1.0 : 0.42)
                .accessibilityLabel(entry.dayLabel)
                .accessibilityValue("\(entry.category.label): \(entry.tokens) tokens")
            }
            if let selectedBreakdown {
                RuleMark(x: .value("Day", selectedBreakdown.0))
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(
                        position: ChartStyle.inspectorPlacement(index: selectedBreakdown.0, totalCount: self.breakdowns.count).annotationPosition,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        ChartInspectorCard(
                            title: labels[safe: selectedBreakdown.0] ?? "Day",
                            lines: Self.inspectorLines(for: selectedBreakdown.1)
                        )
                    }
            }
        }
        .chartYScale(domain: 0...Double(max(summary.peakDayTotal, 1)) * 1.1)
        .chartForegroundStyleScale(
            domain: TokenCategory.orderedForStack.map(\.label),
            range: ChartStyle.categoryScale
        )
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: yAxisMarks) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel {
                    if let tokens = value.as(Int.self) {
                        Text(Self.compactTokenCount(tokens))
                            .font(.system(size: 8).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: Array(Set(entries.map(\.dayIndex))).sorted()) { value in
                AxisValueLabel {
                    if let index = value.as(Int.self),
                       labels.indices.contains(index) {
                        let label = labels[index]
                        let today = labels.last
                        Text(label)
                            .font(.system(size: 9, weight: label == today ? .semibold : .regular).monospacedDigit())
                            .foregroundStyle(label == today ? .primary : .secondary)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        let plotFrame = geometry[proxy.plotFrame!]
                        switch phase {
                        case .active(let location):
                            let x = location.x - plotFrame.origin.x
                            guard
                                x >= 0,
                                x <= proxy.plotSize.width,
                                let rawDayIndex = proxy.value(atX: x, as: Int.self)
                            else {
                                ChartStyle.updateHoverSelection(&self.selectedDayIndex, to: nil)
                                return
                            }
                            let dayIndex = min(max(rawDayIndex, 0), max(self.breakdowns.count - 1, 0))
                            guard
                                let snappedX = proxy.position(forX: dayIndex),
                                abs(snappedX - x) <= ChartStyle.snapThreshold(
                                    plotWidth: proxy.plotSize.width,
                                    itemCount: self.breakdowns.count
                                )
                            else {
                                ChartStyle.updateHoverSelection(&self.selectedDayIndex, to: nil)
                                return
                            }
                            ChartStyle.updateHoverSelection(&self.selectedDayIndex, to: dayIndex)
                        case .ended:
                            ChartStyle.updateHoverSelection(&self.selectedDayIndex, to: nil)
                        }
                    }
            }
        }
        .animation(ChartStyle.animation, value: entries)
        .animation(ChartStyle.hoverAnimation, value: self.selectedDayIndex)
    }

    private func summaryRow(_ summary: Summary) -> some View {
        HStack(spacing: 6) {
            self.summaryMetric(
                label: "Window",
                value: Self.compactTokenCount(summary.totalTokens),
                detail: "7-day total"
            )
            self.summaryMetric(
                label: "Peak",
                value: Self.dayLabels(count: self.breakdowns.count)[safe: summary.peakDayIndex] ?? "Day",
                detail: Self.compactTokenCount(summary.peakDayTotal)
            )
            self.summaryMetric(
                label: "Today",
                value: Self.compactTokenCount(summary.todayTotal),
                detail: "Avg \(Self.compactTokenCount(summary.averageDailyTokens))/day"
            )
        }
    }

    private func summaryMetric(label: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Color.primary.opacity(0.48))
            Text(value)
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(detail)
                .font(.system(size: 8))
                .foregroundStyle(Color.primary.opacity(0.55))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }

    nonisolated static func entries(from breakdowns: [TokenBreakdown]) -> [Entry] {
        let labels = Self.dayLabels(count: breakdowns.count)
        var result: [Entry] = []
        result.reserveCapacity(breakdowns.count * TokenCategory.orderedForStack.count)
        for (offset, breakdown) in breakdowns.enumerated() {
            let isLast = offset == breakdowns.count - 1
            let label = isLast ? "Today" : labels[offset]
            for category in TokenCategory.orderedForStack {
                let tokens = category.value(for: breakdown)
                if tokens > 0 {
                    result.append(
                        Entry(
                            dayIndex: offset,
                            dayLabel: label,
                            category: category,
                            tokens: tokens
                        )
                    )
                }
            }
        }
        return result
    }

    nonisolated static func tooltip(for breakdowns: [TokenBreakdown]) -> String {
        let labels = Self.dayLabels(count: breakdowns.count)
        return breakdowns.enumerated().map { offset, breakdown in
            let label = offset == breakdowns.count - 1 ? "Today" : labels[offset]
            let detail = TokenCategory.orderedForStack.compactMap { category -> String? in
                let tokens = category.value(for: breakdown)
                guard tokens > 0 else { return nil }
                return "\(category.shortLabel) \(Self.compactTokenCount(tokens))"
            }
            .joined(separator: " · ")
            let total = Self.compactTokenCount(breakdown.total)
            return detail.isEmpty ? "\(label): no tokens" : "\(label): \(total) total · \(detail)"
        }
        .joined(separator: "\n")
    }

    nonisolated static func inspectorLines(for breakdown: TokenBreakdown) -> [String] {
        let total = max(breakdown.total, 1)
        return ["Total \(Self.compactTokenCount(breakdown.total))"] + TokenCategory.orderedForStack.compactMap { category in
            let tokens = category.value(for: breakdown)
            guard tokens > 0 else { return nil }
            return "\(category.shortLabel) \(Self.compactTokenCount(tokens)) · \(Self.percentLabel(Double(tokens) / Double(total)))"
        }
    }

    nonisolated static func summary(from breakdowns: [TokenBreakdown]) -> Summary? {
        guard !breakdowns.isEmpty else { return nil }
        let totals = breakdowns.map(\.total)
        let totalTokens = totals.reduce(0, +)
        let peakDayIndex = totals.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let peakDayTotal = totals[safe: peakDayIndex] ?? 0
        return Summary(
            totalTokens: totalTokens,
            averageDailyTokens: breakdowns.isEmpty ? 0 : totalTokens / breakdowns.count,
            peakDayIndex: peakDayIndex,
            peakDayTotal: peakDayTotal,
            todayTotal: totals.last ?? 0
        )
    }

    nonisolated static func yAxisMarks(maxTotal: Int) -> [Int] {
        let peak = max(maxTotal, 1)
        let midpoint = max(peak / 2, 1)
        return Array(Set([0, midpoint, peak])).sorted()
    }

    nonisolated private static func dayLabels(count: Int) -> [String] {
        let raw = ChartDayLabels.lastNDays(count)
        guard !raw.isEmpty else { return raw }
        var labels = raw
        labels[labels.count - 1] = "Today"
        return labels
    }

    nonisolated private static func compactTokenCount(_ count: Int) -> String {
        let value = Double(count)
        if value >= 1_000_000_000 {
            return String(format: "%.1fB", value / 1_000_000_000)
        }
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        }
        return "\(count)"
    }

    nonisolated private static func percentLabel(_ value: Double) -> String {
        String(format: "%.0f%%", max(0, min(1, value)) * 100)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard self.indices.contains(index) else { return nil }
        return self[index]
    }
}

#Preview("Stack — 7 days") {
    let sample = [
        TokenBreakdown(input: 1_200, output: 800, cacheRead: 4_500, cacheCreation: 300, reasoningOutput: 0),
        TokenBreakdown(input: 900, output: 2_100, cacheRead: 8_200, cacheCreation: 450, reasoningOutput: 120),
        TokenBreakdown(input: 0, output: 0, cacheRead: 0, cacheCreation: 0, reasoningOutput: 0),
        TokenBreakdown(input: 1_500, output: 1_800, cacheRead: 12_000, cacheCreation: 500, reasoningOutput: 50),
        TokenBreakdown(input: 2_200, output: 3_500, cacheRead: 18_000, cacheCreation: 900, reasoningOutput: 200),
        TokenBreakdown(input: 1_800, output: 2_200, cacheRead: 10_000, cacheCreation: 600, reasoningOutput: 150),
        TokenBreakdown(input: 2_500, output: 4_000, cacheRead: 20_000, cacheCreation: 1_100, reasoningOutput: 300),
    ]
    return TokenStackChart(breakdowns: sample)
        .padding()
        .frame(width: 320)
}
