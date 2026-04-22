import HeimdallDomain
import HeimdallServices
import Testing
@testable import HeimdallAppUI

struct AppShellModelTests {
    @MainActor
    @Test
    func navigationItemsIncludeLiveMonitor() {
        let model = AppShellModel(
            sessionStore: AppSessionStore(
                config: .default,
                selectedProvider: .claude,
                selectedMergeTab: .overview,
                persistence: TestAppSessionStateStore()
            )
        )

        #expect(model.navigationItems.contains(AppNavigationItem.liveMonitor))
    }
}

private struct TestAppSessionStateStore: AppSessionStatePersisting {
    func loadAppSessionState() -> PersistedAppSessionState? { nil }
    func saveAppSessionState(_: PersistedAppSessionState) {}
}
