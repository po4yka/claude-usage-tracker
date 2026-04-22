import Charts
import HeimdallDomain
import SwiftUI

/// 30-day running-sum cost curve ("budget pace").
/// Each entry accumulates all prior days' costs. The curve is monotonically
/// non-decreasing by construction. Days with unparseable date strings are
/// skipped; the running sum continues across gaps.
struct CumulativeSpendChart: View {
    let daily: [CostHistoryPoint]

    struct Entry: Identifiable, Hashable {
        let day: Date
        let cumulativeCostUSD: Double
        var id: Date { self.day }
    }

    var body: some View {
        let entries = Self.entries(from: self.daily)
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Cumulative spend, 30 days",
                caption: "Running total. The line is always monotonic."
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
        .accessibilityLabel("Cumulative spend, last \(entries.count) days")
    }

    private func chart(entries: [Entry]) -> some View {
        Chart {
            ForEach(entries) { entry in
                AreaMark(
                    x: .value("Day", entry.day),
                    y: .value("Cumulative cost", entry.cumulativeCostUSD)
                )
                .foregroundStyle(ChartStyle.areaFill)
                .interpolationMethod(.monotone)
            }
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Day", entry.day),
                    y: .value("Cumulative cost", entry.cumulativeCostUSD)
                )
                .foregroundStyle(ChartStyle.lineStroke)
                .lineStyle(StrokeStyle(lineWidth: ChartStyle.lineWidth, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
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
        var running = 0.0
        return daily.compactMap { point in
            guard let date = Self.dayFormatter.date(from: point.day) else { return nil }
            running += point.costUSD
            return Entry(day: date, cumulativeCostUSD: running)
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

#Preview("Cumulative spend — plateaus and spikes") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    let base = Date()
    let calendar = Calendar.current
    // Alternating active days (cost > 0) and plateau days (cost = 0) to show
    // monotonicity clearly: curve steps up then holds flat.
    let dailyCosts: [Double] = [
        3.2, 0.0, 0.0, 5.8, 1.1, 0.0, 4.4,
        2.9, 0.0, 0.0, 6.1, 0.0, 3.3, 1.7,
        0.0, 4.8, 0.0, 0.0, 7.2, 2.5, 0.0,
        3.6, 1.4, 0.0, 5.5, 0.0, 2.1, 4.0,
        0.0, 8.3,
    ]
    let points: [CostHistoryPoint] = dailyCosts.enumerated().map { offset, cost in
        let date = calendar.date(byAdding: .day, value: -(29 - offset), to: base) ?? base
        return CostHistoryPoint(
            day: formatter.string(from: date),
            totalTokens: Int(cost * 1_000),
            costUSD: cost
        )
    }
    return CumulativeSpendChart(daily: points)
        .padding()
        .frame(width: 360)
}
