import Foundation
import HeimdallDomain

@MainActor
public final class HeimdallAppRuntime {
    public let sessionStore: AppSessionStore
    public let providerRepository: ProviderRepository
    public let refreshCoordinator: RefreshCoordinator
    public let authCoordinator: AuthCoordinator
    public let settingsStore: any SettingsStore
    public let credentialInspector: any ProviderCredentialInspecting
    public let liveMonitorClientFactory: @Sendable (Int) -> any LiveMonitorClient
    public let localNotificationCoordinator: any LocalNotificationCoordinating
    public let cloudSyncController: (any CloudSyncControlling)?
    private let cloudKitAccountObserver: CloudKitAccountObserver?

    public init(
        sessionStore: AppSessionStore,
        providerRepository: ProviderRepository,
        refreshCoordinator: RefreshCoordinator,
        authCoordinator: AuthCoordinator,
        settingsStore: any SettingsStore,
        credentialInspector: any ProviderCredentialInspecting,
        liveMonitorClientFactory: @escaping @Sendable (Int) -> any LiveMonitorClient,
        localNotificationCoordinator: any LocalNotificationCoordinating,
        cloudSyncController: (any CloudSyncControlling)? = nil,
        observesCloudKitAccount: Bool = false
    ) {
        self.sessionStore = sessionStore
        self.providerRepository = providerRepository
        self.refreshCoordinator = refreshCoordinator
        self.authCoordinator = authCoordinator
        self.settingsStore = settingsStore
        self.credentialInspector = credentialInspector
        self.liveMonitorClientFactory = liveMonitorClientFactory
        self.localNotificationCoordinator = localNotificationCoordinator
        self.cloudSyncController = cloudSyncController
        if observesCloudKitAccount, cloudSyncController != nil {
            let observer = CloudKitAccountObserver { [weak sessionStore] in
                Task { @MainActor in
                    sessionStore?.cloudSyncState = CloudSyncSpaceState()
                }
            }
            observer.start()
            self.cloudKitAccountObserver = observer
        } else {
            self.cloudKitAccountObserver = nil
        }
    }
}
