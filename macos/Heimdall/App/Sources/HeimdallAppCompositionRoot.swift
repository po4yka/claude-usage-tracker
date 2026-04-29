import Foundation
import HeimdallAppUI
import HeimdallPlatformMac
import HeimdallServices

struct HeimdallAppCompositionRoot {
    @MainActor
    func appModel() -> AppModel {
        let platformRoot = MacPlatformCompositionRoot()
        let cloudSyncEnabled = MacPlatformCompositionRoot.shouldEnableCloudKitSnapshotSync()

        let cloudSyncStatePersistence: any CloudSyncStatePersisting
        let cloudSyncStore: (any SnapshotSyncStore)?
        if cloudSyncEnabled {
            let persistence = UserDefaultsCloudSyncStateStore()
            cloudSyncStatePersistence = persistence
            cloudSyncStore = CloudKitSnapshotSyncStore(persistence: persistence)
        } else {
            cloudSyncStatePersistence = NoopCloudSyncStateStore()
            cloudSyncStore = nil
        }

        let runtime = platformRoot.appRuntime(
            cloudSyncStore: cloudSyncStore,
            cloudSyncStatePersistence: cloudSyncStatePersistence,
            cloudSyncDiagnosticsContext: cloudSyncEnabled ? Self.cloudSyncDiagnosticsContext() : nil,
            observesCloudKitAccount: cloudSyncStore != nil
        )
        let model = AppModel(runtime: runtime)
        model.start()
        return model
    }

    private static func cloudSyncDiagnosticsContext() -> CloudSyncDiagnosticsContext {
        CloudSyncDiagnosticsContext(
            containerIdentifier: CloudKitSnapshotSyncStore.defaultContainerIdentifier,
            defaultZoneName: SnapshotCloudEngine.zoneName,
            stateFileURL: try? FileBackedCloudKitSyncEngineStateStore.defaultURL()
        )
    }
}
