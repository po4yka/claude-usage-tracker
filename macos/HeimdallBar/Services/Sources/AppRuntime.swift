import Foundation
import HeimdallDomain

public struct CloudSyncDiagnosticsContext: Sendable {
    public var containerIdentifier: String
    public var defaultZoneName: String
    public var stateFileURL: URL?

    public init(
        containerIdentifier: String,
        defaultZoneName: String,
        stateFileURL: URL?
    ) {
        self.containerIdentifier = containerIdentifier
        self.defaultZoneName = defaultZoneName
        self.stateFileURL = stateFileURL
    }
}

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
    public let cloudSyncDiagnosticsContext: CloudSyncDiagnosticsContext?
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
        cloudSyncDiagnosticsContext: CloudSyncDiagnosticsContext? = nil,
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
        self.cloudSyncDiagnosticsContext = cloudSyncDiagnosticsContext
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
