import Charts
import HeimdallDomain
import SwiftUI

/// Donut chart for a single period's token mix. Companion to `TokenBreakdownRow`:
/// the row gives the proportional rail, the donut gives a sector view useful when
/// comparing two periods side-by-side or when the total is large enough that the
/// ring conveys magnitude better than a thin bar.
struct TokenBreakdownDonut: View {
    let title: String
    let breakdown: TokenBreakdown
    var diameter: CGFloat = 96

    struct Entry: Identifiable, Hashable {
        let category: TokenCategory
        let tokens: Int
        var id: String { self.category.label }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Token mix",
                caption: "\(self.title) · total \(Self.compactTokenCount(self.breakdown.total))"
            )
            HStack(alignment: .center, spacing: 10) {
                self.donutView
                TokenCategoryLegend()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(8)
        .menuCardBackground(
            opacity: ChartStyle.cardBackgroundOpacity,
            cornerRadius: ChartStyle.cardCornerRadius
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Token mix donut for \(self.title)")
    }

    @ViewBuilder
    private var donutView: some View {
        if self.breakdown.isEmpty {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    .frame(width: self.diameter, height: self.diameter)
                Text("No tokens\nrecorded yet.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: self.diameter * 0.6)
            }
            .frame(width: self.diameter, height: self.diameter)
        } else {
            let entries = Self.entries(from: self.breakdown)
            ZStack {
                Chart(entries) { entry in
                    SectorMark(
                        angle: .value("Tokens", entry.tokens),
                        innerRadius: .ratio(0.62),
                        outerRadius: .ratio(0.98)
                    )
                    .foregroundStyle(by: .value("Category", entry.category.label))
                    .accessibilityLabel(entry.category.label)
                    .accessibilityValue("\(Self.compactTokenCount(entry.tokens)) tokens")
                }
                .chartForegroundStyleScale(
                    domain: TokenCategory.orderedForStack.map(\.label),
                    range: ChartStyle.categoryScale
                )
                .chartLegend(.hidden)
                .frame(width: self.diameter, height: self.diameter)
                .animation(ChartStyle.animation, value: entries)

                VStack(spacing: 1) {
                    Text(Self.compactTokenCount(self.breakdown.total))
                        .font(.headline.monospacedDigit().weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(self.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: self.diameter * 0.58)
            }
            .frame(width: self.diameter, height: self.diameter)
        }
    }

    nonisolated static func entries(from breakdown: TokenBreakdown) -> [Entry] {
        TokenCategory.orderedForStack.compactMap { category in
            let tokens = category.value(for: breakdown)
            guard tokens > 0 else { return nil }
            return Entry(category: category, tokens: tokens)
        }
    }

    nonisolated static func compactTokenCount(_ count: Int) -> String {
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
}

#Preview("Today — mixed breakdown") {
    TokenBreakdownDonut(
        title: "Today",
        breakdown: TokenBreakdown(
            input: 12_400,
            output: 8_750,
            cacheRead: 42_300,
            cacheCreation: 3_100,
            reasoningOutput: 1_850
        )
    )
    .padding()
    .frame(width: 320)
}

#Preview("30 days — large breakdown") {
    TokenBreakdownDonut(
        title: "30 days",
        breakdown: TokenBreakdown(
            input: 4_820_000,
            output: 3_150_000,
            cacheRead: 18_400_000,
            cacheCreation: 1_270_000,
            reasoningOutput: 640_000
        ),
        diameter: 96
    )
    .padding()
    .frame(width: 320)
}
