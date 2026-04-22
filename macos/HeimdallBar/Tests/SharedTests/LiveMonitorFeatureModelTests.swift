import Foundation
import HeimdallDomain
import HeimdallServices
import Testing
@testable import HeimdallAppUI

struct LiveMonitorFeatureModelTests {
    @MainActor
    @Test
    func updateActivityStartsAndStopsFastPolling() async throws {
        let client = StubLiveMonitorClient(envelope: Self.sampleEnvelope(defaultFocus: .all))
        let model = LiveMonitorFeatureModel(
            sessionStore: AppSessionStore(persistence: TestAppSessionStateStore()),
            clientFactory: { _ in client },
            pollInterval: .milliseconds(20),
            reconnectInitialDelayNanoseconds: 1_000_000,
            reconnectMaxDelayNanoseconds: 5_000_000
        )

        model.updateActivity(isSelected: true, appIsActive: true)
        try await Task.sleep(nanoseconds: 70_000_000)
        let activeFetches = client.fetchCount
        #expect(activeFetches >= 2)

        model.updateActivity(isSelected: false, appIsActive: true)
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(client.fetchCount == activeFetches)
    }

    @MainActor
    @Test
    func scanCompletedEventTriggersImmediateRefetchAfterReconnect() async throws {
        let client = StubLiveMonitorClient(
            envelope: Self.sampleEnvelope(defaultFocus: .codex),
            failFirstStream: true
        )
        let model = LiveMonitorFeatureModel(
            sessionStore: AppSessionStore(persistence: TestAppSessionStateStore()),
            clientFactory: { _ in client },
            pollInterval: .seconds(60),
            reconnectInitialDelayNanoseconds: 1_000_000,
            reconnectMaxDelayNanoseconds: 5_000_000
        )

        model.updateActivity(isSelected: true, appIsActive: true)
        try await Task.sleep(nanoseconds: 20_000_000)
        #expect(model.focus == LiveMonitorFocus.codex)
        let initialFetches = client.fetchCount

        client.emit("scan_completed")
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(client.fetchCount > initialFetches)
        #expect(model.providers.count == 1)
        #expect(model.providers.first?.providerID == .codex)
    }

    private static func sampleEnvelope(defaultFocus: LiveMonitorFocus) -> LiveMonitorEnvelope {
        LiveMonitorEnvelope(
            generatedAt: "2026-04-22T10:00:00Z",
            defaultFocus: defaultFocus,
            globalIssue: nil,
            freshness: LiveMonitorFreshness(
                newestProviderRefresh: "2026-04-22T10:00:00Z",
                oldestProviderRefresh: "2026-04-22T09:59:00Z",
                staleProviders: [],
                hasStaleProviders: false,
                refreshState: "current"
            ),
            providers: [
                LiveMonitorProvider(
                    provider: "claude",
                    title: "Claude",
                    visualState: "healthy",
                    sourceLabel: "Source: oauth",
                    warnings: [],
                    identityLabel: "pro",
                    primary: ProviderRateWindow(
                        usedPercent: 25,
                        resetsAt: nil,
                        resetsInMinutes: 10,
                        windowMinutes: 300,
                        resetLabel: "resets in 10m"
                    ),
                    todayCostUSD: 3.2,
                    projectedWeeklySpendUSD: 20,
                    lastRefresh: "2026-04-22T10:00:00Z",
                    lastRefreshLabel: "Updated just now"
                ),
                LiveMonitorProvider(
                    provider: "codex",
                    title: "Codex",
                    visualState: "healthy",
                    sourceLabel: "Source: cli-rpc",
                    warnings: [],
                    identityLabel: nil,
                    primary: nil,
                    todayCostUSD: 1.1,
                    projectedWeeklySpendUSD: 8.4,
                    lastRefresh: "2026-04-22T10:00:00Z",
                    lastRefreshLabel: "Updated just now"
                ),
            ]
        )
    }
}

private final class StubLiveMonitorClient: LiveMonitorClient, @unchecked Sendable {
    private struct State {
        var continuation: AsyncThrowingStream<String, Error>.Continuation?
        var failFirstStream: Bool
        var fetchCount = 0
        var streamRequestCount = 0
    }

    private let lock = NSLock()
    private let envelope: LiveMonitorEnvelope
    private var state: State

    var fetchCount: Int {
        self.lock.withLock {
            self.state.fetchCount
        }
    }

    init(envelope: LiveMonitorEnvelope, failFirstStream: Bool = false) {
        self.envelope = envelope
        self.state = State(failFirstStream: failFirstStream)
    }

    func fetchLiveMonitor() async throws -> LiveMonitorEnvelope {
        self.lock.withLock {
            self.state.fetchCount += 1
        }
        return self.envelope
    }

    func liveMonitorEvents() -> AsyncThrowingStream<String, Error> {
        let shouldFail = self.lock.withLock {
            self.state.streamRequestCount += 1
            return self.state.failFirstStream && self.state.streamRequestCount == 1
        }

        if shouldFail {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: URLError(.networkConnectionLost))
            }
        }

        return AsyncThrowingStream { continuation in
            self.lock.withLock {
                self.state.continuation = continuation
            }
        }
    }

    func emit(_ event: String) {
        let continuation = self.lock.withLock {
            self.state.continuation
        }
        continuation?.yield(event)
    }
}

private struct TestAppSessionStateStore: AppSessionStatePersisting {
    func loadAppSessionState() -> PersistedAppSessionState? { nil }
    func saveAppSessionState(_: PersistedAppSessionState) {}
}
