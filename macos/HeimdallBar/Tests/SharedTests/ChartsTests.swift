import Foundation
import Testing
@testable import HeimdallAppUI
@testable import HeimdallDomain

struct ChartsTests {
    @Test
    func historyBarChartEntriesIndexInOrderAndMarkToday() {
        let entries = HistoryBarChart.entries(from: [0.1, 0.3, -0.2, 1.4, 0.5, 0.0, 0.75])
        #expect(entries.count == 7)
        let indices = entries.map(\.index)
        #expect(indices == [0, 1, 2, 3, 4, 5, 6])
        #expect(entries.last?.label == "Today")
        let clampedLow = entries[2].fraction
        let clampedHigh = entries[3].fraction
        #expect(clampedLow == 0.0)
        #expect(clampedHigh == 1.0)
    }

    @Test
    func historyBarChartEntriesEmptyWhenNoFractions() {
        #expect(HistoryBarChart.entries(from: []).isEmpty)
    }

    @Test
    func tokenStackChartEntriesEmitOnePerNonZeroCategoryInStableOrder() {
        let breakdowns = [
            TokenBreakdown(input: 10, output: 0, cacheRead: 5, cacheCreation: 0, reasoningOutput: 0),
            TokenBreakdown(input: 0, output: 0, cacheRead: 0, cacheCreation: 0, reasoningOutput: 0),
            TokenBreakdown(input: 1, output: 2, cacheRead: 3, cacheCreation: 4, reasoningOutput: 5),
        ]
        let entries = TokenStackChart.entries(from: breakdowns)

        // Day 0: 2 categories (input, cacheRead). Day 1: 0. Day 2: 5.
        #expect(entries.count == 2 + 0 + 5)

        let day0 = entries.filter { $0.dayIndex == 0 }
        #expect(day0.map(\.category) == [.input, .cacheRead])
        #expect(day0.map(\.tokens) == [10, 5])

        let day2 = entries.filter { $0.dayIndex == 2 }
        #expect(day2.map(\.category) == TokenCategory.orderedForStack)
        #expect(day2.map(\.tokens) == [1, 2, 3, 4, 5])

        #expect(entries.last?.dayLabel == "Today")
    }

    @Test
    func tokenStackChartEntriesHandleEmptyInput() {
        #expect(TokenStackChart.entries(from: []).isEmpty)
    }

    @Test
    func dailyCostChartEntriesParseIsoDaysAndPassCostsThrough() {
        let daily = [
            CostHistoryPoint(day: "2026-04-18", totalTokens: 0, costUSD: 2.5),
            CostHistoryPoint(day: "2026-04-19", totalTokens: 0, costUSD: 3.75),
            CostHistoryPoint(day: "not-a-date", totalTokens: 0, costUSD: 9.99),
            CostHistoryPoint(day: "2026-04-20", totalTokens: 0, costUSD: 1.0),
        ]
        let entries = DailyCostChart.entries(from: daily)
        let count = entries.count
        #expect(count == 3)
        let costs = entries.map(\.costUSD)
        #expect(costs == [2.5, 3.75, 1.0])
    }

    @Test
    func dailyCostChartEntriesEmptyOnEmptyInput() {
        let empty: [CostHistoryPoint] = []
        let result = DailyCostChart.entries(from: empty)
        #expect(result.isEmpty)
    }

    @Test
    func dailyCostChartEntriesSkipUnparseableDays() {
        let daily = [
            CostHistoryPoint(day: "not-a-date", totalTokens: 0, costUSD: 1.0),
            CostHistoryPoint(day: "2026-04-20", totalTokens: 0, costUSD: 2.0),
        ]
        let entries = DailyCostChart.entries(from: daily)
        let count = entries.count
        let cost = entries.first?.costUSD
        #expect(count == 1)
        #expect(cost == 2.0)
    }
}
