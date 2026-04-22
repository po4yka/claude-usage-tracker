import Charts
import HeimdallDomain
import SwiftUI

/// 30-day daily cost line + area chart. New visualization unlocked by Swift
/// Charts: the menu previously only had the normalized 7-day strip; the full
/// `CostHistoryPoint` series has always been in the snapshot but was not
/// rendered anywhere. Today's point is marked by an accent rule.
struct DailyCostChart: View {
    let daily: [CostHistoryPoint]

    struct Entry: Identifiable, Hashable {
        let day: Date
        let costUSD: Double
        var id: Date { self.day }
    }

    var body: some View {
        let entries = Self.entries(from: self.daily)
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Daily cost",
                caption: "Last \(entries.count) days. The vertical line marks today."
            )
            if entries.isEmpty {
                Text("No daily data yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                self.chart(entries: entries)
                    .frame(height: 72)
            }
        }
        .padding(8)
        .menuCardBackground(
            opacity: ChartStyle.cardBackgroundOpacity,
            cornerRadius: ChartStyle.cardCornerRadius
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily cost, last \(entries.count) days")
    }

    private func chart(entries: [Entry]) -> some View {
        let today = entries.last?.day
        return Chart {
            ForEach(entries) { entry in
                AreaMark(
                    x: .value("Day", entry.day),
                    y: .value("Cost", entry.costUSD)
                )
                .foregroundStyle(ChartStyle.areaFill)
                .interpolationMethod(.monotone)
            }
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Day", entry.day),
                    y: .value("Cost", entry.costUSD)
                )
                .foregroundStyle(ChartStyle.lineStroke)
                .lineStyle(StrokeStyle(lineWidth: ChartStyle.lineWidth, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
            }
            if let today = today {
                RuleMark(x: .value("Today", today))
                    .foregroundStyle(ChartStyle.todayRuleStroke)
                    .lineStyle(StrokeStyle(lineWidth: ChartStyle.todayRuleWidth, dash: [2, 2]))
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
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
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .animation(ChartStyle.animation, value: entries)
    }

    nonisolated static func entries(from daily: [CostHistoryPoint]) -> [Entry] {
        daily.compactMap { point in
            guard let date = Self.dayFormatter.date(from: point.day) else {
                return nil
            }
            return Entry(day: date, costUSD: point.costUSD)
        }
    }

    nonisolated(unsafe) private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    nonisolated(unsafe) private static let axisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

#Preview("Daily cost — 30 days") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    let base = Date()
    let calendar = Calendar.current
    let points: [CostHistoryPoint] = (0..<30).reversed().map { offset in
        let date = calendar.date(byAdding: .day, value: -offset, to: base) ?? base
        let amp = Double(30 - offset) / 30.0
        let cost = 2.0 + amp * 18.0 + Double(offset % 4) * 1.5
        return CostHistoryPoint(day: formatter.string(from: date), totalTokens: 0, costUSD: cost)
    }
    return DailyCostChart(daily: points)
        .padding()
        .frame(width: 360)
}
