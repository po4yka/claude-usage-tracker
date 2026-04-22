import Charts
import HeimdallDomain
import SwiftUI

/// Compact per-MCP-server activity table with a proportional invocation bar.
struct McpSummaryTable: View {
    let rows: [ProviderMcpRow]

    private static let displayCap = 8

    var body: some View {
        let capped = Array(self.rows.prefix(Self.displayCap))
        VStack(alignment: .leading, spacing: 6) {
            ChartHeader(
                title: "MCP servers · 30 days",
                caption: "Server activity."
            )
            if capped.isEmpty {
                Text("No MCP server data yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                let maxInvocations = capped.map(\.invocations).max() ?? 1
                VStack(spacing: 6) {
                    ForEach(capped) { row in
                        McpServerRow(row: row, maxInvocations: maxInvocations)
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
        .accessibilityLabel("MCP servers, \(min(rows.count, Self.displayCap)) servers")
    }

    nonisolated static func formatInvocations(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000     { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

private struct McpServerRow: View {
    let row: ProviderMcpRow
    let maxInvocations: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Name + call count
            HStack(alignment: .firstTextBaseline) {
                Text(self.row.server)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(McpSummaryTable.formatInvocations(self.row.invocations)) calls")
                    .font(.body.monospacedDigit().weight(.semibold))
                    .fixedSize()
            }

            // Proportional bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color.primary.opacity(0.55))
                        .frame(
                            width: max(
                                2,
                                geo.size.width * CGFloat(self.row.invocations) / CGFloat(max(self.maxInvocations, 1))
                            ),
                            height: 3
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
            }
            .frame(height: 3)

            // Tools · sessions caption
            Text("\(self.row.toolsUsed) tools · \(self.row.sessionsUsed) sessions")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("MCP servers — 4 rows") {
    let rows: [ProviderMcpRow] = [
        ProviderMcpRow(server: "context7", invocations: 440, toolsUsed: 2, sessionsUsed: 18),
        ProviderMcpRow(server: "codex-mcp", invocations: 88, toolsUsed: 3, sessionsUsed: 9),
        ProviderMcpRow(server: "chrome-devtools", invocations: 55, toolsUsed: 12, sessionsUsed: 6),
        ProviderMcpRow(server: "mcp-atlassian", invocations: 14, toolsUsed: 7, sessionsUsed: 3),
    ]
    McpSummaryTable(rows: rows)
        .padding()
        .frame(width: 336)
}
