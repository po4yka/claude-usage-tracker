import Charts
import HeimdallDomain
import SwiftUI

/// Compact per-model cost table with a per-row token-composition mini bar.
/// Consumes `ProviderModelRow` from `HeimdallDomain`; rendering is pure —
/// no domain mutations occur here.
struct ModelCostTable: View {
    let rows: [ProviderModelRow]

    // Safety cap: caller truncates to top N, but guard here too.
    private static let displayCap = 8

    var body: some View {
        let capped = Array(self.rows.prefix(Self.displayCap))
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Model cost · 30 days",
                caption: "Top models by spend."
            )
            if capped.isEmpty {
                Text("No model data yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(capped) { row in
                        ModelCostRow(row: row)
                    }
                }
            }
        }
        .padding(8)
        .menuCardBackground(
            opacity: ChartStyle.cardBackgroundOpacity,
            cornerRadius: ChartStyle.cardCornerRadius
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Model cost, top \(capped.count) models")
    }

    /// Cost formatted consistently with the rest of the bar.
    nonisolated static func formatCost(_ usd: Double) -> String {
        if usd >= 1000 { return String(format: "$%.0f", usd) }
        if usd >= 10   { return String(format: "$%.1f", usd) }
        return String(format: "$%.2f", usd)
    }
}

private struct ModelCostRow: View {
    let row: ProviderModelRow

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.truncatedModelName(self.row.model))
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(ModelCostTable.formatCost(self.row.costUSD))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .fixedSize()
            }
            GeometryReader { geo in
                Self.compositionBar(row: self.row, width: geo.size.width)
            }
            .frame(height: 4)
        }
    }

    private static func truncatedModelName(_ name: String) -> String {
        // Keep up to 36 characters; SwiftUI truncationMode(.middle) handles the rest.
        name
    }

    // Proportional composition bar: input / output / cacheRead / cacheCreation / reasoning.
    @ViewBuilder
    private static func compositionBar(row: ProviderModelRow, width: CGFloat) -> some View {
        let total = max(1, row.input + row.output + row.cacheRead + row.cacheCreation + row.reasoningOutput)
        let categories: [(Int, Color)] = [
            (row.input,           TokenCategory.input.tint),
            (row.output,          TokenCategory.output.tint),
            (row.cacheRead,       TokenCategory.cacheRead.tint),
            (row.cacheCreation,   TokenCategory.cacheCreation.tint),
            (row.reasoningOutput, TokenCategory.reasoning.tint),
        ]
        HStack(spacing: 0) {
            ForEach(Array(categories.enumerated()), id: \.offset) { entry in
                let (tokens, tint) = entry.element
                if tokens > 0 {
                    Rectangle()
                        .fill(tint)
                        .frame(
                            width: max(1, width * CGFloat(tokens) / CGFloat(total)),
                            height: 4
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }
}

// MARK: - Preview

#Preview("Model cost — 5 rows") {
    let rows: [ProviderModelRow] = [
        ProviderModelRow(model: "claude-opus-4-5", costUSD: 42.80, input: 120_000, output: 18_000, cacheRead: 540_000, cacheCreation: 22_000, reasoningOutput: 8_000, turns: 190),
        ProviderModelRow(model: "claude-sonnet-4-5", costUSD: 18.35, input: 80_000, output: 14_000, cacheRead: 300_000, cacheCreation: 10_000, reasoningOutput: 0, turns: 420),
        ProviderModelRow(model: "claude-haiku-3-5", costUSD: 3.12, input: 45_000, output: 9_000, cacheRead: 120_000, cacheCreation: 4_000, reasoningOutput: 0, turns: 810),
        ProviderModelRow(model: "gpt-5", costUSD: 1.55, input: 22_000, output: 4_000, cacheRead: 0, cacheCreation: 0, reasoningOutput: 3_000, turns: 55),
        ProviderModelRow(model: "claude-opus-4-0-20250514-thinking", costUSD: 0.88, input: 8_000, output: 2_000, cacheRead: 15_000, cacheCreation: 1_200, reasoningOutput: 12_000, turns: 12),
    ]
    ModelCostTable(rows: rows)
        .padding()
        .frame(width: 336)
}
