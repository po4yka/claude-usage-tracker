import Charts
import HeimdallDomain
import SwiftUI

/// 7 × 24 heatmap of turn activity. Rows = days of week (Sun–Sat),
/// columns = hours 0–23. Intensity is opacity of `Color.primary`.
struct ActivityHeatmap: View {
    let cells: [ProviderHeatmapCell]

    nonisolated private static let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private static let hourTicks = [0, 6, 12, 18, 23]
    private static let dayLabelWidth: CGFloat = 30
    private static let cellSpacing: CGFloat = 3

    struct Summary: Equatable {
        let totalTurns: Int
        let activeCells: Int
        let peakTurns: Int
        let peakDay: Int
        let peakHour: Int
    }

    struct IntensityScale: Equatable {
        struct Level: Equatable, Identifiable {
            let threshold: Int
            let opacity: Double

            var id: Int { self.threshold * 100 + Int(self.opacity * 100) }
        }

        let levels: [Level]

        func opacity(for turns: Int) -> Double {
            guard turns > 0 else { return 0.04 }
            return self.levels.last(where: { turns >= $0.threshold })?.opacity ?? 0.14
        }
    }

    var body: some View {
        let grid = Self.lookup(self.cells)
        let maxTurns = grid.flatMap { $0 }.max() ?? 0
        let summary = Self.summary(from: grid)
        let scale = Self.intensityScale(for: grid)
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Activity heatmap · 30 days",
                caption: "Stepped opacity scale keeps quieter hours visible.",
                trailing: summary.map { summary in
                    AnyView(
                        Text("\(summary.totalTurns) turns")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Color.primary.opacity(0.62))
                    )
                }
            )
            if maxTurns == 0 {
                Text("No heatmap data yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                self.heatmapGrid(grid: grid, summary: summary, scale: scale)
            }
        }
        .padding(8)
        .menuCardBackground(
            opacity: ChartStyle.cardBackgroundOpacity,
            cornerRadius: ChartStyle.cardCornerRadius
        )
        .help(Self.tooltip(grid: grid, summary: summary))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Activity heatmap, 7 days by 24 hours")
    }

    @ViewBuilder
    private func heatmapGrid(grid: [[Int]], summary: Summary?, scale: IntensityScale) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let summary {
                self.summaryRow(summary)
                    .padding(.bottom, 4)
            }
            self.legendRow(scale)
                .padding(.bottom, 5)
            VStack(spacing: Self.cellSpacing) {
                ForEach(0..<7, id: \.self) { day in
                    HStack(alignment: .center, spacing: 8) {
                        Text(Self.dayLabels[day])
                            .font(.system(size: 8, weight: .medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: Self.dayLabelWidth, alignment: .leading)
                        HStack(spacing: Self.cellSpacing) {
                            ForEach(0..<24, id: \.self) { hour in
                                let turns = grid[day][hour]
                                let isPeak = summary?.peakDay == day && summary?.peakHour == hour
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(Self.fillColor(turns: turns, scale: scale))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                                            .stroke(Color.primary.opacity(turns > 0 ? 0.1 : 0.04), lineWidth: 0.6)
                                    }
                                    .overlay {
                                        if isPeak {
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .stroke(Color.primary.opacity(0.9), lineWidth: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .accessibilityLabel("\(Self.dayLabels[day]) \(Self.hourLabel(hour))")
                                    .accessibilityValue("\(turns) turns")
                                    .help("\(Self.dayLabels[day]) \(Self.hourLabel(hour)): \(turns) turns")
                            }
                        }
                    }
                }
            }
            HStack(alignment: .center, spacing: 8) {
                Text("Hour")
                    .font(.system(size: 8, weight: .medium).monospacedDigit())
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .frame(width: Self.dayLabelWidth, alignment: .leading)
                HStack(spacing: Self.cellSpacing) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(Self.hourTicks.contains(hour) ? Self.hourLabel(hour) : "")
                            .font(.system(size: 8).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: Self.tickAlignment(for: hour))
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func legendRow(_ scale: IntensityScale) -> some View {
        HStack(spacing: 8) {
            Text("Scale")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Color.primary.opacity(0.48))
            ForEach(scale.levels) { level in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.primary.opacity(level.opacity))
                        .frame(width: 10, height: 10)
                    Text("\(Self.turnLabel(level.threshold))+")
                        .font(.system(size: 8).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func summaryRow(_ summary: Summary) -> some View {
        HStack(spacing: 6) {
            self.summaryMetric(
                label: "Peak",
                value: "\(Self.dayLabels[summary.peakDay]) \(Self.hourLabel(summary.peakHour))",
                detail: "\(summary.peakTurns) turns"
            )
            self.summaryMetric(
                label: "Active",
                value: "\(summary.activeCells) cells",
                detail: "with activity"
            )
            self.summaryMetric(
                label: "Cadence",
                value: summary.activeCells > 0
                    ? String(format: "%.1f", Double(summary.totalTurns) / Double(summary.activeCells))
                    : "0.0",
                detail: "avg turns/cell"
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
                .minimumScaleFactor(0.8)
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

    nonisolated static func summary(from grid: [[Int]]) -> Summary? {
        guard !grid.isEmpty else { return nil }

        var totalTurns = 0
        var activeCells = 0
        var peakTurns = 0
        var peakDay = 0
        var peakHour = 0

        for day in 0..<min(7, grid.count) {
            for hour in 0..<min(24, grid[day].count) {
                let turns = grid[day][hour]
                totalTurns += turns
                if turns > 0 {
                    activeCells += 1
                }
                if turns > peakTurns {
                    peakTurns = turns
                    peakDay = day
                    peakHour = hour
                }
            }
        }

        guard totalTurns > 0 else { return nil }
        return Summary(
            totalTurns: totalTurns,
            activeCells: activeCells,
            peakTurns: peakTurns,
            peakDay: peakDay,
            peakHour: peakHour
        )
    }

    nonisolated static func tooltip(grid: [[Int]], summary: Summary?) -> String {
        var lines: [String] = []
        if let summary {
            lines.append("Peak: \(Self.dayLabels[summary.peakDay]) \(Self.hourLabel(summary.peakHour)) · \(summary.peakTurns) turns")
            lines.append("Active cells: \(summary.activeCells)")
            lines.append("Total turns: \(summary.totalTurns)")
        }
        for day in 0..<min(7, grid.count) {
            let activeHours = grid[day].enumerated().compactMap { hour, turns -> String? in
                guard turns > 0 else { return nil }
                return "\(Self.hourLabel(hour)) \(turns)"
            }
            if !activeHours.isEmpty {
                lines.append("\(Self.dayLabels[day]): \(activeHours.joined(separator: " · "))")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Build a 7×24 matrix (day × hour) of turn counts from sparse cells.
    nonisolated static func lookup(_ cells: [ProviderHeatmapCell]) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 24), count: 7)
        for cell in cells {
            let day = max(0, min(6, cell.dayOfWeek))
            let hour = max(0, min(23, cell.hour))
            grid[day][hour] += cell.turns
        }
        return grid
    }

    nonisolated static func intensityScale(for grid: [[Int]]) -> IntensityScale {
        let active = grid
            .flatMap { $0 }
            .filter { $0 > 0 }
            .sorted()

        guard !active.isEmpty else { return IntensityScale(levels: []) }

        let candidates = [
            1,
            Self.quantile(active, fraction: 0.35),
            Self.quantile(active, fraction: 0.6),
            Self.quantile(active, fraction: 0.85),
            active.last ?? 1,
        ]

        let thresholds = candidates.reduce(into: [Int]()) { result, value in
            let clamped = max(1, value)
            if result.last != clamped {
                result.append(clamped)
            }
        }

        let opacityRamp: [Double] = [0.14, 0.24, 0.38, 0.58, 0.82]
        let levels = thresholds.enumerated().map { index, threshold in
            IntensityScale.Level(
                threshold: threshold,
                opacity: opacityRamp[min(index, opacityRamp.count - 1)]
            )
        }
        return IntensityScale(levels: levels)
    }

    private static func fillColor(turns: Int, scale: IntensityScale) -> Color {
        Color.primary.opacity(scale.opacity(for: turns))
    }

    nonisolated private static func hourLabel(_ hour: Int) -> String {
        String(format: "%02d", hour)
    }

    nonisolated private static func turnLabel(_ turns: Int) -> String {
        if turns >= 1_000 {
            return String(format: "%.1fK", Double(turns) / 1_000)
        }
        return "\(turns)"
    }

    private static func tickAlignment(for hour: Int) -> Alignment {
        if hour == 0 {
            return .leading
        }
        if hour == 23 {
            return .trailing
        }
        return .center
    }

    nonisolated private static func quantile(_ values: [Int], fraction: Double) -> Int {
        guard !values.isEmpty else { return 0 }
        let clamped = max(0, min(1, fraction))
        let index = Int((Double(values.count - 1) * clamped).rounded())
        return values[index]
    }
}

// MARK: - Preview

#Preview("Activity heatmap — weekday mornings/afternoons") {
    let sample: [ProviderHeatmapCell] = {
        var result: [ProviderHeatmapCell] = []
        // Weekdays (Mon=1 .. Fri=5): morning cluster 9–11, afternoon 14–17
        for day in 1...5 {
            for hour in 9...11 {
                result.append(ProviderHeatmapCell(dayOfWeek: day, hour: hour, turns: Int.random(in: 8...30)))
            }
            for hour in 14...17 {
                result.append(ProviderHeatmapCell(dayOfWeek: day, hour: hour, turns: Int.random(in: 15...50)))
            }
            // Light evening
            for hour in 19...21 {
                result.append(ProviderHeatmapCell(dayOfWeek: day, hour: hour, turns: Int.random(in: 2...10)))
            }
        }
        // Light weekend activity
        result.append(ProviderHeatmapCell(dayOfWeek: 0, hour: 10, turns: 5))
        result.append(ProviderHeatmapCell(dayOfWeek: 6, hour: 11, turns: 8))
        return result
    }()
    ActivityHeatmap(cells: sample)
        .padding()
        .frame(width: 320)
}
