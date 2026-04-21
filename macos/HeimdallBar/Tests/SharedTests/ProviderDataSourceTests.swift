import Foundation
import HeimdallDomain
import HeimdallServices
import Testing

struct ProviderDataSourceTests {
    @Test
    func syncedProviderDataSourceFiltersProviderSnapshots() async throws {
        let dataSource = SyncedProviderDataSource(client: StubSyncProviderClient())

        let envelope = try await dataSource.fetchSnapshots(
            config: .default,
            refresh: true,
            provider: .codex
        )

        #expect(envelope.providers.count == 1)
        #expect(envelope.providers.first?.providerID == .codex)
        #expect(envelope.requestedProvider == "codex")
        #expect(envelope.responseScope == "provider")
    }

    @Test
    func syncedProviderDataSourceDerivesCostSummaryFromSnapshots() async throws {
        let dataSource = SyncedProviderDataSource(client: StubSyncProviderClient())

        let envelope = try await dataSource.fetchCostSummary(
            config: .default,
            provider: .claude
        )

        #expect(envelope.provider == "claude")
        #expect(envelope.summary.todayTokens == 1200)
        #expect(envelope.summary.last30DaysCostUSD == 45.0)
    }
}

private struct StubSyncProviderClient: SyncProviderClient {
    func fetchSyncedSnapshots() async throws -> ProviderSnapshotEnvelope {
        ProviderSnapshotEnvelope(
            contractVersion: LiveProviderContract.version,
            providers: [
                ProviderSnapshot(
                    provider: "claude",
                    available: true,
                    sourceUsed: "sync",
                    lastAttemptedSource: "sync",
                    resolvedViaFallback: false,
                    refreshDurationMs: 0,
                    sourceAttempts: [],
                    identity: nil,
                    primary: nil,
                    secondary: nil,
                    tertiary: nil,
                    credits: nil,
                    status: nil,
                    auth: Self.syncedAuthHealth,
                    costSummary: ProviderCostSummary(
                        todayTokens: 1200,
                        todayCostUSD: 12.5,
                        last30DaysTokens: 4500,
                        last30DaysCostUSD: 45.0,
                        daily: []
                    ),
                    claudeUsage: nil,
                    lastRefresh: "2026-04-21T09:00:00Z",
                    stale: false,
                    error: nil
                ),
                ProviderSnapshot(
                    provider: "codex",
                    available: true,
                    sourceUsed: "sync",
                    lastAttemptedSource: "sync",
                    resolvedViaFallback: false,
                    refreshDurationMs: 0,
                    sourceAttempts: [],
                    identity: nil,
                    primary: nil,
                    secondary: nil,
                    tertiary: nil,
                    credits: nil,
                    status: nil,
                    auth: Self.syncedAuthHealth,
                    costSummary: ProviderCostSummary(
                        todayTokens: 800,
                        todayCostUSD: 8.0,
                        last30DaysTokens: 3200,
                        last30DaysCostUSD: 32.0,
                        daily: []
                    ),
                    claudeUsage: nil,
                    lastRefresh: "2026-04-21T09:00:00Z",
                    stale: false,
                    error: nil
                ),
            ],
            fetchedAt: "2026-04-21T09:00:00Z",
            requestedProvider: nil,
            responseScope: "all",
            cacheHit: false,
            refreshedProviders: ["claude", "codex"]
        )
    }

    private static let syncedAuthHealth = ProviderAuthHealth(
        loginMethod: "sync",
        credentialBackend: "remote",
        authMode: "sync",
        isAuthenticated: true,
        isRefreshable: true,
        isSourceCompatible: true,
        requiresRelogin: false,
        managedRestriction: nil,
        diagnosticCode: "authenticated-compatible",
        failureReason: nil,
        lastValidatedAt: "2026-04-21T09:00:00Z",
        recoveryActions: []
    )
}
