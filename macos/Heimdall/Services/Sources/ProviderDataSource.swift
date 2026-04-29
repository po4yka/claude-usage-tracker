import Foundation
import HeimdallDomain

public struct SyncedProviderDataSource: ProviderDataSource {
    private let client: any SyncProviderClient

    public init(client: any SyncProviderClient) {
        self.client = client
    }

    public func fetchSnapshots(
        config _: HeimdallConfig,
        refresh _: Bool,
        provider: ProviderID?
    ) async throws -> ProviderSnapshotEnvelope {
        let envelope = try await self.client.fetchSyncedSnapshots()
        guard let provider else {
            return envelope
        }

        let filteredProviders = envelope.providers.filter { $0.providerID == provider }
        return ProviderSnapshotEnvelope(
            contractVersion: envelope.contractVersion,
            providers: filteredProviders,
            fetchedAt: envelope.fetchedAt,
            requestedProvider: provider.rawValue,
            responseScope: "provider",
            cacheHit: envelope.cacheHit,
            refreshedProviders: filteredProviders.compactMap(\.providerID?.rawValue)
        )
    }

    public func fetchCostSummary(
        config: HeimdallConfig,
        provider: ProviderID
    ) async throws -> CostSummaryEnvelope {
        let envelope = try await self.fetchSnapshots(config: config, refresh: false, provider: provider)
        let summary = envelope.providers.first(where: { $0.providerID == provider })?.costSummary ?? ProviderCostSummary(
            todayTokens: 0,
            todayCostUSD: 0,
            last30DaysTokens: 0,
            last30DaysCostUSD: 0,
            daily: []
        )
        return CostSummaryEnvelope(provider: provider.rawValue, summary: summary)
    }
}
