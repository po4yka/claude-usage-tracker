import SwiftUI

struct WeeklyProjectionArc: View {
    let projectedCostUSD: Double
    /// 0.0 … 1.0, fraction of the weekly window that has elapsed so far.
    /// Typically `1.0 - (weeklyLane.remainingPercent / 100.0)`.
    let elapsedFraction: Double
    var diameter: CGFloat = 96

    var body: some View {
        let elapsed = max(0.0, min(1.0, self.elapsedFraction))
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                // Background arc: 3/4 sweep, open gap facing upward.
                // trim(from: 0.125, to: 0.875) gives a 3/4 arc.
                // rotationEffect(.degrees(90)) rotates so the open gap is at the top.
                Circle()
                    .trim(from: 0.125, to: 0.875)
                    .stroke(
                        Color.primary.opacity(0.12),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Foreground arc: fills from left end up to elapsedFraction of the 3/4 sweep.
                Circle()
                    .trim(from: 0.125, to: 0.125 + 0.75 * elapsed)
                    .stroke(
                        Color.accentColor.opacity(0.85),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Center labels.
                VStack(spacing: 1) {
                    Text(self.projectionLabel)
                        .font(.headline.monospacedDigit().weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("proj.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: self.diameter, height: self.diameter)

            VStack(alignment: .leading, spacing: 3) {
                Text("Projected weekly")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                Text("\(Int((elapsed * 100).rounded()))% of week elapsed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(8)
        .menuCardBackground(opacity: ChartStyle.cardBackgroundOpacity, cornerRadius: ChartStyle.cardCornerRadius)
        .help("Linear extrapolation of the current weekly window's spend at the current pace.")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly projection")
        .accessibilityValue("\(self.projectionLabel), \(Int((elapsed * 100).rounded())) percent of week elapsed")
    }

    private var projectionLabel: String {
        if self.projectedCostUSD >= 1000 {
            return String(format: "$%.0f", self.projectedCostUSD)
        }
        if self.projectedCostUSD >= 10 {
            return String(format: "$%.1f", self.projectedCostUSD)
        }
        return String(format: "$%.2f", self.projectedCostUSD)
    }
}

#Preview("Early week — 5% elapsed, $120") {
    WeeklyProjectionArc(projectedCostUSD: 120.0, elapsedFraction: 0.05)
        .padding()
        .frame(width: 300)
}

#Preview("Mid-week — 45% elapsed, $78.40") {
    WeeklyProjectionArc(projectedCostUSD: 78.40, elapsedFraction: 0.45)
        .padding()
        .frame(width: 300)
}

#Preview("End of week — 92% elapsed, $1500") {
    WeeklyProjectionArc(projectedCostUSD: 1500.0, elapsedFraction: 0.92)
        .padding()
        .frame(width: 300)
}
