import CloudKit
import Foundation
import HeimdallDomain

public enum SnapshotSyncStoreError: Error, LocalizedError, Equatable, Sendable {
    case encodeFailed(String)
    case decodeFailed(String)
    case transportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .encodeFailed(let detail):
            return "Failed to encode mobile snapshot payload: \(detail)"
        case .decodeFailed(let detail):
            return "Failed to decode mobile snapshot payload: \(detail)"
        case .transportFailed(let detail):
            return "CloudKit snapshot sync failed: \(detail)"
        }
    }
}

protocol CloudSnapshotBackingStore: Sendable {
    func accountStatus() async throws -> CKAccountStatus
    func fetchInstallationSnapshots(state: CloudSyncSpaceState) async throws -> [SyncedInstallationSnapshot]
    func saveInstallationSnapshot(
        _ snapshot: SyncedInstallationSnapshot,
        state: CloudSyncSpaceState
    ) async throws -> CloudSyncSpaceState
    func prepareOwnerShare(state: CloudSyncSpaceState) async throws -> CloudSyncSpaceState
    func acceptShareURL(_ url: URL, state: CloudSyncSpaceState) async throws -> CloudSyncSpaceState
}

public struct CloudKitSnapshotSyncStore: SnapshotSyncStore {
    public static let defaultContainerIdentifier = "iCloud.dev.heimdall.heimdallbar"

    private let backingStore: any CloudSnapshotBackingStore
    private let persistence: any CloudSyncStatePersisting
    private let installationIDStore: any InstallationIDPersisting

    public init(
        containerIdentifier: String = Self.defaultContainerIdentifier,
        persistence: any CloudSyncStatePersisting = UserDefaultsCloudSyncStateStore(),
        installationIDStore: any InstallationIDPersisting = KeychainInstallationIDStore()
    ) {
        let stateStoreURL = (try? FileBackedCloudKitSyncEngineStateStore.defaultURL())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("heimdall-sync-engine-state.json")
        let stateStore = FileBackedCloudKitSyncEngineStateStore(fileURL: stateStoreURL)
        let backingStore = SnapshotCloudEngine(
            containerIdentifier: containerIdentifier,
            stateStore: stateStore
        )
        self.init(
            backingStore: backingStore,
            persistence: persistence,
            installationIDStore: installationIDStore
        )
    }

    init(
        backingStore: any CloudSnapshotBackingStore,
        persistence: any CloudSyncStatePersisting = UserDefaultsCloudSyncStateStore(),
        installationIDStore: any InstallationIDPersisting = KeychainInstallationIDStore()
    ) {
        self.backingStore = backingStore
        self.persistence = persistence
        self.installationIDStore = installationIDStore
    }

    public func loadLiveAggregateSnapshot() async throws -> SyncedAggregateEnvelope? {
        let state = try await self.loadCloudSyncSpaceState()
        let installations = try await self.backingStore.fetchInstallationSnapshots(state: state)
        guard !installations.isEmpty else { return nil }
        let generatedAt = installations.map(\.publishedAt).max() ?? ISO8601DateFormatter().string(from: Date())
        return SyncedAggregateEnvelope.aggregate(
            installations: installations,
            generatedAt: generatedAt
        )
    }

    public func loadAggregateSnapshot() async throws -> SyncedAggregateEnvelope? {
        try await self.loadLiveAggregateSnapshot()
    }

    public func saveLatestSnapshot(_ snapshot: MobileSnapshotEnvelope) async throws -> SyncedAggregateEnvelope {
        let installationSnapshot = SyncedInstallationSnapshot.from(
            mobileSnapshot: snapshot,
            installationID: self.installationID
        )
        let state = try await self.loadCloudSyncSpaceState()
        let nextState = try await self.backingStore.saveInstallationSnapshot(
            installationSnapshot,
            state: state
        )
        self.persistence.saveCloudSyncSpaceState(nextState)

        let installations = try await self.backingStore.fetchInstallationSnapshots(state: nextState)
        let merged = installations.isEmpty ? [installationSnapshot] : installations
        return SyncedAggregateEnvelope.aggregate(
            installations: merged,
            generatedAt: snapshot.generatedAt
        )
    }

    public func loadCloudSyncSpaceState() async throws -> CloudSyncSpaceState {
        let persisted = self.persistence.loadCloudSyncSpaceState() ?? CloudSyncSpaceState()
        let status = try await self.backingStore.accountStatus()
        switch status {
        case .available:
            return persisted
        case .restricted:
            return CloudSyncSpaceState(
                role: persisted.role,
                status: .sharingBlocked,
                shareURL: persisted.shareURL,
                zoneName: persisted.zoneName,
                zoneOwnerName: persisted.zoneOwnerName,
                lastPublishedAt: persisted.lastPublishedAt,
                lastAcceptedAt: persisted.lastAcceptedAt,
                statusMessage: "CloudKit sharing is restricted on this device."
            )
        case .noAccount, .couldNotDetermine, .temporarilyUnavailable:
            return CloudSyncSpaceState(
                role: persisted.role,
                status: .iCloudUnavailable,
                shareURL: persisted.shareURL,
                zoneName: persisted.zoneName,
                zoneOwnerName: persisted.zoneOwnerName,
                lastPublishedAt: persisted.lastPublishedAt,
                lastAcceptedAt: persisted.lastAcceptedAt,
                statusMessage: "Sign in to iCloud to enable Cloud Sync."
            )
        @unknown default:
            return persisted
        }
    }

    public func prepareOwnerShare() async throws -> CloudSyncSpaceState {
        let state = try await self.loadCloudSyncSpaceState()
        let nextState = try await self.backingStore.prepareOwnerShare(state: state)
        self.persistence.saveCloudSyncSpaceState(nextState)
        return nextState
    }

    public func acceptShareURL(_ url: URL) async throws -> CloudSyncSpaceState {
        let state = try await self.loadCloudSyncSpaceState()
        let nextState = try await self.backingStore.acceptShareURL(url, state: state)
        self.persistence.saveCloudSyncSpaceState(nextState)
        return nextState
    }

    private var installationID: String {
        if let persisted = self.installationIDStore.loadInstallationID(), !persisted.isEmpty {
            return persisted
        }
        let generated = UUID().uuidString.lowercased()
        self.installationIDStore.saveInstallationID(generated)
        return generated
    }
}
