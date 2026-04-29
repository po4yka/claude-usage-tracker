import Charts
import SwiftUI

/// 7-day (or N-day) spend bars using Swift Charts. Replaces the hand-rolled
/// `HistoryBarStrip` fractions mode. Y-domain is fixed 0...1 because the
/// caller already normalizes each day to the window peak, matching the
/// previous "share of peak" semantics.
struct HistoryBarChart: View {
    let fractions: [Double]
    var showsHeader: Bool = true
    /// When true, the chart renders without its own card background or
    /// padding. Use from a parent view that already provides a card —
    /// otherwise you end up with a card-in-a-card.
    var inset: Bool = false
    @State private var selectedIndex: Int?

    struct Entry: Identifiable, Hashable {
        let index: Int
        let label: String
        let fraction: Double

        var id: Int { self.index }
    }

    struct Summary: Equatable {
        let averageFraction: Double
        let latestFraction: Double
        let peakEntry: Entry
    }

    /// Minimum on-screen bar height so zero-spend days still render a
    /// visible stub and the axis doesn't look broken. The real fraction
    /// is still reported to VoiceOver via `accessibilityValue`.
    private static let minimumVisibleFraction: Double = 0.04

    var body: some View {
        let entries = Self.entries(from: self.fractions)
        let summary = Self.summary(from: entries)
        let content = VStack(alignment: .leading, spacing: 6) {
            if self.showsHeader {
                ChartHeader(
                    title: "Usage history",
                    caption: "Daily spend normalized to the peak day in view."
                )
            }
            VStack(alignment: .leading, spacing: 8) {
                if let summary {
                    self.summaryRow(summary)
                }
                self.chart(entries: entries, summary: summary)
                    .frame(height: 132)
                self.labels(entries: entries)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Usage history, last \(entries.count) days")

        if self.inset {
            content
        } else {
            content
                .padding(8)
                .menuCardBackground(
                    opacity: ChartStyle.cardBackgroundOpacity,
                    cornerRadius: ChartStyle.cardCornerRadius
                )
        }
    }

    private func chart(entries: [Entry], summary: Summary?) -> some View {
        let selectedEntry = self.selectedIndex.flatMap { index in
            entries.first(where: { $0.index == index })
        }
        return Chart {
            RuleMark(y: .value("Half", 0.5))
                .foregroundStyle(Color.primary.opacity(0.08))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))

            RuleMark(y: .value("Peak", 1.0))
                .foregroundStyle(Color.primary.opacity(0.14))
                .lineStyle(StrokeStyle(lineWidth: 1))

            ForEach(entries) { entry in
                BarMark(
                    x: .value("Day", entry.index),
                    y: .value("Fraction", max(Self.minimumVisibleFraction, entry.fraction)),
                    width: .fixed(24)
                )
                .foregroundStyle(self.barTint(for: entry, in: entries))
                .cornerRadius(ChartStyle.barCornerRadius)
                .accessibilityLabel(entry.label)
                .accessibilityValue("\(Int((entry.fraction * 100).rounded())) percent of peak")
            }
            if let selectedEntry {
                RuleMark(x: .value("Day", selectedEntry.index))
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(
                        position: ChartStyle.inspectorPlacement(index: selectedEntry.index, totalCount: entries.count).annotationPosition,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        ChartInspectorCard(
                            title: selectedEntry.label,
                            lines: Self.inspectorLines(for: selectedEntry, entries: entries, summary: summary)
                        )
                    }
            }
        }
        .chartXScale(domain: -0.45...Double(max(entries.count - 1, 0)) + 0.45)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0.0, 0.5, 1.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel {
                    if let fraction = value.as(Double.self) {
                        Text(Self.percentLabel(fraction))
                            .font(.system(size: 8).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis(.hidden)
        .chartPlotStyle { plot in
            plot
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.025))
                )
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
                                let rawIndex = proxy.value(atX: x, as: Int.self)
                            else {
                                ChartStyle.updateHoverSelection(&self.selectedIndex, to: nil)
                                return
                            }
                            let index = min(max(rawIndex, 0), max(entries.count - 1, 0))
                            guard
                                let snappedX = proxy.position(forX: index),
                                abs(snappedX - x) <= ChartStyle.snapThreshold(
                                    plotWidth: proxy.plotSize.width,
                                    itemCount: entries.count
                                )
                            else {
                                ChartStyle.updateHoverSelection(&self.selectedIndex, to: nil)
                                return
                            }
                            ChartStyle.updateHoverSelection(&self.selectedIndex, to: index)
                        case .ended:
                            ChartStyle.updateHoverSelection(&self.selectedIndex, to: nil)
                        }
                    }
            }
        }
        .help(Self.tooltip(for: entries))
        .animation(ChartStyle.animation, value: entries)
        .animation(ChartStyle.hoverAnimation, value: self.selectedIndex)
    }

    @ViewBuilder
    private func labels(entries: [Entry]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(entries) { entry in
                Text(entry.label)
                    .font(.system(size: 11, weight: self.isToday(entry, in: entries) ? .semibold : .regular).monospacedDigit())
                    .foregroundStyle(self.isToday(entry, in: entries) ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
    }

    private func summaryRow(_ summary: Summary) -> some View {
        HStack(spacing: 6) {
            self.summaryMetric(
                label: "Peak",
                value: summary.peakEntry.label,
                detail: Self.percentLabel(summary.peakEntry.fraction)
            )
            self.summaryMetric(
                label: "Today",
                value: Self.percentLabel(summary.latestFraction),
                detail: "of peak"
            )
            self.summaryMetric(
                label: "Average",
                value: Self.percentLabel(summary.averageFraction),
                detail: "window baseline"
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

    private func isToday(_ entry: Entry, in entries: [Entry]) -> Bool {
        entry.index == entries.count - 1
    }

    private func barTint(for entry: Entry, in entries: [Entry]) -> Color {
        if self.selectedIndex == entry.index {
            return Color.accentColor
        }
        return self.isToday(entry, in: entries) ? ChartStyle.barTodayFill : ChartStyle.barFill
    }

    nonisolated static func entries(from fractions: [Double]) -> [Entry] {
        let labels = Self.dayLabels(count: fractions.count)
        return fractions.enumerated().map { offset, fraction in
            let isLast = offset == fractions.count - 1
            return Entry(
                index: offset,
                label: isLast ? "Today" : labels[offset],
                fraction: max(0, min(1, fraction))
            )
        }
    }

    nonisolated static func tooltip(for entries: [Entry]) -> String {
        entries.map { entry in
            "\(entry.label): \(Int((entry.fraction * 100).rounded()))% of peak"
        }
        .joined(separator: "\n")
    }

    nonisolated static func summary(from entries: [Entry]) -> Summary? {
        guard let peakEntry = entries.max(by: { $0.fraction < $1.fraction }) else { return nil }
        let averageFraction = entries.isEmpty
            ? 0
            : entries.reduce(0.0) { $0 + $1.fraction } / Double(entries.count)
        return Summary(
            averageFraction: averageFraction,
            latestFraction: entries.last?.fraction ?? 0,
            peakEntry: peakEntry
        )
    }

    nonisolated static func inspectorLines(for entry: Entry, entries: [Entry], summary: Summary?) -> [String] {
        let sorted = entries.sorted { lhs, rhs in
            if lhs.fraction == rhs.fraction {
                return lhs.index < rhs.index
            }
            return lhs.fraction > rhs.fraction
        }
        let rank = (sorted.firstIndex(of: entry) ?? 0) + 1
        var lines = ["\(Self.percentLabel(entry.fraction)) of peak", "Rank \(rank) of \(entries.count)"]
        if let summary {
            let delta = entry.fraction - summary.averageFraction
            lines.append("\(delta >= 0 ? "+" : "")\(Self.percentLabel(abs(delta))) vs avg")
        }
        return lines
    }

    nonisolated static func percentLabel(_ value: Double) -> String {
        String(format: "%.0f%%", max(0, min(1, value)) * 100)
    }

    nonisolated private static func dayLabels(count: Int) -> [String] {
        ChartDayLabels.lastNDays(count)
    }
}

#Preview("History — 7 days") {
    HistoryBarChart(fractions: [0.12, 0.34, 0.08, 0.66, 0.9, 0.4, 0.72])
        .padding()
        .frame(width: 320)
}

#Preview("History — no header") {
    HistoryBarChart(
        fractions: [0.05, 0.2, 0.45, 0.6, 0.3, 0.85, 1.0],
        showsHeader: false
    )
    .padding()
    .frame(width: 320)
}
