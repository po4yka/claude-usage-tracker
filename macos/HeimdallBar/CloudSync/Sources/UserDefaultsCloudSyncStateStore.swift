import Foundation
import HeimdallDomain
import HeimdallServices

public final class UserDefaultsCloudSyncStateStore: @unchecked Sendable, CloudSyncStatePersisting {
    private enum Keys {
        static let cloudSyncState = "heimdallbar.cloud_sync.state"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadCloudSyncSpaceState() -> CloudSyncSpaceState? {
        guard let data = self.defaults.data(forKey: Keys.cloudSyncState) else {
            return nil
        }
        return try? self.decoder.decode(CloudSyncSpaceState.self, from: data)
    }

    public func saveCloudSyncSpaceState(_ state: CloudSyncSpaceState) {
        guard let data = try? self.encoder.encode(state) else { return }
        self.defaults.set(data, forKey: Keys.cloudSyncState)
    }
}
