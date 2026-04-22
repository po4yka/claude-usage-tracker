import Charts
import HeimdallDomain
import SwiftUI

/// Compact per-project cost table with a proportional spend bar per row.
struct ProjectCostTable: View {
    let rows: [ProviderProjectRow]

    private static let displayCap = 8

    var body: some View {
        let capped = Array(self.rows.prefix(Self.displayCap))
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "Top projects · 30 days",
                caption: "Spend by project."
            )
            if capped.isEmpty {
                Text("No project data yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                let maxCost = capped.map(\.costUSD).max() ?? 1
                VStack(spacing: 4) {
                    ForEach(capped) { row in
                        ProjectCostRow(row: row, maxCost: maxCost)
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
        .accessibilityLabel("Top projects by spend, \(min(rows.count, Self.displayCap)) rows")
    }

    nonisolated static func formatCost(_ usd: Double) -> String {
        if usd >= 1000 { return String(format: "$%.0f", usd) }
        if usd >= 10   { return String(format: "$%.1f", usd) }
        return String(format: "$%.2f", usd)
    }
}

private struct ProjectCostRow: View {
    let row: ProviderProjectRow
    let maxCost: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(self.row.displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(ProjectCostTable.formatCost(self.row.costUSD))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .fixedSize()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color.primary.opacity(0.55))
                        .frame(
                            width: max(2, geo.size.width * CGFloat(self.row.costUSD / max(self.maxCost, 1e-9))),
                            height: 3
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Preview

#Preview("Project cost — 5 rows") {
    let rows: [ProviderProjectRow] = [
        ProviderProjectRow(project: "heimdall", displayName: "heimdall", costUSD: 38.40, turns: 1_240, sessions: 42),
        ProviderProjectRow(project: "infra-platform", displayName: "infra-platform", costUSD: 21.75, turns: 870, sessions: 28),
        ProviderProjectRow(project: "my-saas-app", displayName: "my-saas-app", costUSD: 9.12, turns: 390, sessions: 14),
        ProviderProjectRow(project: "scratch", displayName: "scratch", costUSD: 2.88, turns: 155, sessions: 9),
        ProviderProjectRow(project: "untitled", displayName: "untitled", costUSD: 0.44, turns: 18, sessions: 3),
    ]
    ProjectCostTable(rows: rows)
        .padding()
        .frame(width: 336)
}
