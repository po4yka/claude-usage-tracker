import Foundation

// Internal merge helpers for ProviderCostSummary.merging(_:).
// Kept internal (not private) so they are accessible from ProviderCostSummary.swift
// within the same module (HeimdallDomain).
enum ProviderCostSummaryMerge {
    static func weightedRate(
        lhsRate: Double?,
        lhsWeight: Int,
        rhsRate: Double?,
        rhsWeight: Int
    ) -> Double? {
        let lhsComponent = lhsRate.map { ($0, max(lhsWeight, 0)) }
        let rhsComponent = rhsRate.map { ($0, max(rhsWeight, 0)) }
        let components = [lhsComponent, rhsComponent].compactMap { $0 }.filter { $0.1 > 0 }
        guard !components.isEmpty else {
            return [lhsRate, rhsRate].compactMap { $0 }.first
        }
        let totalWeight = components.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return nil }
        let weightedValue = components.reduce(0.0) { partial, component in
            partial + (component.0 * Double(component.1))
        }
        return weightedValue / Double(totalWeight)
    }

    static func models(_ lhs: [ProviderModelRow], _ rhs: [ProviderModelRow]) -> [ProviderModelRow] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.model)
        let mergedRows: [ProviderModelRow] = groupedRows.map { model, rows in
            let costUSD = rows.reduce(0.0) { partial, row in partial + row.costUSD }
            let input = rows.reduce(0) { partial, row in partial + row.input }
            let output = rows.reduce(0) { partial, row in partial + row.output }
            let cacheRead = rows.reduce(0) { partial, row in partial + row.cacheRead }
            let cacheCreation = rows.reduce(0) { partial, row in partial + row.cacheCreation }
            let reasoningOutput = rows.reduce(0) { partial, row in partial + row.reasoningOutput }
            let turns = rows.reduce(0) { partial, row in partial + row.turns }
            return ProviderModelRow(
                model: model,
                costUSD: costUSD,
                input: input,
                output: output,
                cacheRead: cacheRead,
                cacheCreation: cacheCreation,
                reasoningOutput: reasoningOutput,
                turns: turns
            )
        }
        return mergedRows.sorted(by: sortModels)
    }

    static func projects(_ lhs: [ProviderProjectRow], _ rhs: [ProviderProjectRow]) -> [ProviderProjectRow] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.project)
        let mergedRows: [ProviderProjectRow] = groupedRows.map { project, rows in
            let displayName = rows.first?.displayName ?? project
            let costUSD = rows.reduce(0.0) { partial, row in partial + row.costUSD }
            let turns = rows.reduce(0) { partial, row in partial + row.turns }
            let sessions = rows.reduce(0) { partial, row in partial + row.sessions }
            return ProviderProjectRow(
                project: project,
                displayName: displayName,
                costUSD: costUSD,
                turns: turns,
                sessions: sessions
            )
        }
        return mergedRows.sorted(by: sortProjects)
    }

    static func tools(_ lhs: [ProviderToolRow], _ rhs: [ProviderToolRow]) -> [ProviderToolRow] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.id)
        let mergedRows: [ProviderToolRow] = groupedRows.values.map { rows in
            let representative = rows[0]
            let category = rows.compactMap(\.category).first
            let invocations = rows.reduce(0) { partial, row in partial + row.invocations }
            let errors = rows.reduce(0) { partial, row in partial + row.errors }
            let turnsUsed = rows.reduce(0) { partial, row in partial + row.turnsUsed }
            let sessionsUsed = rows.reduce(0) { partial, row in partial + row.sessionsUsed }
            return ProviderToolRow(
                toolName: representative.toolName,
                category: category,
                mcpServer: representative.mcpServer,
                invocations: invocations,
                errors: errors,
                turnsUsed: turnsUsed,
                sessionsUsed: sessionsUsed
            )
        }
        return mergedRows.sorted(by: sortTools)
    }

    static func mcps(_ lhs: [ProviderMcpRow], _ rhs: [ProviderMcpRow]) -> [ProviderMcpRow] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.server)
        let mergedRows: [ProviderMcpRow] = groupedRows.map { server, rows in
            let invocations = rows.reduce(0) { partial, row in partial + row.invocations }
            let toolsUsed = rows.reduce(0) { partial, row in partial + row.toolsUsed }
            let sessionsUsed = rows.reduce(0) { partial, row in partial + row.sessionsUsed }
            return ProviderMcpRow(
                server: server,
                invocations: invocations,
                toolsUsed: toolsUsed,
                sessionsUsed: sessionsUsed
            )
        }
        return mergedRows.sorted(by: sortMcps)
    }

    static func hourly(_ lhs: [ProviderHourlyBucket], _ rhs: [ProviderHourlyBucket]) -> [ProviderHourlyBucket] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.hour)
        let mergedRows: [ProviderHourlyBucket] = groupedRows.map { hour, rows in
            let turns = rows.reduce(0) { partial, row in partial + row.turns }
            let costUSD = rows.reduce(0.0) { partial, row in partial + row.costUSD }
            let tokens = rows.reduce(0) { partial, row in partial + row.tokens }
            return ProviderHourlyBucket(hour: hour, turns: turns, costUSD: costUSD, tokens: tokens)
        }
        return mergedRows.sorted { $0.hour < $1.hour }
    }

    static func heatmap(_ lhs: [ProviderHeatmapCell], _ rhs: [ProviderHeatmapCell]) -> [ProviderHeatmapCell] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.id)
        let mergedRows: [ProviderHeatmapCell] = groupedRows.values.map { rows in
            let representative = rows[0]
            let turns = rows.reduce(0) { partial, row in partial + row.turns }
            return ProviderHeatmapCell(
                dayOfWeek: representative.dayOfWeek,
                hour: representative.hour,
                turns: turns
            )
        }
        return mergedRows.sorted(by: sortHeatmap)
    }

    static func subagents(
        _ lhs: ProviderSubagentBreakdown?,
        _ rhs: ProviderSubagentBreakdown?
    ) -> ProviderSubagentBreakdown? {
        switch (lhs, rhs) {
        case (.none, .none):
            return nil
        case (.some(let value), .none), (.none, .some(let value)):
            return value
        case (.some(let lhsValue), .some(let rhsValue)):
            return ProviderSubagentBreakdown(
                totalTurns: lhsValue.totalTurns + rhsValue.totalTurns,
                totalCostUSD: lhsValue.totalCostUSD + rhsValue.totalCostUSD,
                sessionCount: lhsValue.sessionCount + rhsValue.sessionCount,
                agentCount: lhsValue.agentCount + rhsValue.agentCount
            )
        }
    }

    static func versions(_ lhs: [ProviderVersionRow], _ rhs: [ProviderVersionRow]) -> [ProviderVersionRow] {
        let groupedRows = Dictionary(grouping: lhs + rhs, by: \.version)
        let mergedRows: [ProviderVersionRow] = groupedRows.map { version, rows in
            let turns = rows.reduce(0) { partial, row in partial + row.turns }
            let sessions = rows.reduce(0) { partial, row in partial + row.sessions }
            let costUSD = rows.reduce(0.0) { partial, row in partial + row.costUSD }
            return ProviderVersionRow(version: version, turns: turns, sessions: sessions, costUSD: costUSD)
        }
        return mergedRows.sorted(by: sortVersions)
    }

    static func dailyByModel(
        _ lhs: [ProviderDailyModelRow],
        _ rhs: [ProviderDailyModelRow]
    ) -> [ProviderDailyModelRow] {
        let grouped = Dictionary(grouping: lhs + rhs) { row in
            "\(row.day)|\(row.model)"
        }
        let merged: [ProviderDailyModelRow] = grouped.values.compactMap { rows in
            guard let first = rows.first else { return nil }
            return ProviderDailyModelRow(
                day: first.day,
                model: first.model,
                costUSD: rows.reduce(0.0) { $0 + $1.costUSD },
                input: rows.reduce(0) { $0 + $1.input },
                output: rows.reduce(0) { $0 + $1.output },
                cacheRead: rows.reduce(0) { $0 + $1.cacheRead },
                cacheCreation: rows.reduce(0) { $0 + $1.cacheCreation },
                reasoningOutput: rows.reduce(0) { $0 + $1.reasoningOutput },
                turns: rows.reduce(0) { $0 + $1.turns }
            )
        }
        return merged.sorted { lhs, rhs in
            if lhs.day == rhs.day {
                if lhs.costUSD == rhs.costUSD {
                    return lhs.model < rhs.model
                }
                return lhs.costUSD > rhs.costUSD
            }
            return lhs.day < rhs.day
        }
    }

    private static func sortModels(_ lhs: ProviderModelRow, _ rhs: ProviderModelRow) -> Bool {
        if lhs.costUSD == rhs.costUSD {
            return lhs.model < rhs.model
        }
        return lhs.costUSD > rhs.costUSD
    }

    private static func sortProjects(_ lhs: ProviderProjectRow, _ rhs: ProviderProjectRow) -> Bool {
        if lhs.costUSD == rhs.costUSD {
            return lhs.displayName < rhs.displayName
        }
        return lhs.costUSD > rhs.costUSD
    }

    private static func sortTools(_ lhs: ProviderToolRow, _ rhs: ProviderToolRow) -> Bool {
        if lhs.invocations == rhs.invocations {
            return lhs.id < rhs.id
        }
        return lhs.invocations > rhs.invocations
    }

    private static func sortMcps(_ lhs: ProviderMcpRow, _ rhs: ProviderMcpRow) -> Bool {
        if lhs.invocations == rhs.invocations {
            return lhs.server < rhs.server
        }
        return lhs.invocations > rhs.invocations
    }

    private static func sortHeatmap(_ lhs: ProviderHeatmapCell, _ rhs: ProviderHeatmapCell) -> Bool {
        if lhs.dayOfWeek == rhs.dayOfWeek {
            return lhs.hour < rhs.hour
        }
        return lhs.dayOfWeek < rhs.dayOfWeek
    }

    private static func sortVersions(_ lhs: ProviderVersionRow, _ rhs: ProviderVersionRow) -> Bool {
        if lhs.costUSD == rhs.costUSD {
            return lhs.version < rhs.version
        }
        return lhs.costUSD > rhs.costUSD
    }
}
