import CloudKit
import Foundation

public protocol CloudKitSyncEngineStatePersisting: Sendable {
    func loadState() async throws -> CKSyncEngine.State.Serialization?
    func saveState(_ state: CKSyncEngine.State.Serialization) async throws
    func purgeState() async throws
}

public actor FileBackedCloudKitSyncEngineStateStore: CloudKitSyncEngineStatePersisting {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public static func defaultURL(
        subdirectory: String = "HeimdallSync",
        filename: String = "sync-engine-state.json"
    ) throws -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseURL.appendingPathComponent(subdirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    public func loadState() async throws -> CKSyncEngine.State.Serialization? {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: self.fileURL)
        return try self.decoder.decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    public func saveState(_ state: CKSyncEngine.State.Serialization) async throws {
        let directory = self.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try self.encoder.encode(state)
        try data.write(to: self.fileURL, options: .atomic)
    }

    public func purgeState() async throws {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: self.fileURL)
    }
}

public actor InMemoryCloudKitSyncEngineStateStore: CloudKitSyncEngineStatePersisting {
    private var state: CKSyncEngine.State.Serialization?

    public init(initial: CKSyncEngine.State.Serialization? = nil) {
        self.state = initial
    }

    public func loadState() async throws -> CKSyncEngine.State.Serialization? {
        self.state
    }

    public func saveState(_ state: CKSyncEngine.State.Serialization) async throws {
        self.state = state
    }

    public func purgeState() async throws {
        self.state = nil
    }
}
