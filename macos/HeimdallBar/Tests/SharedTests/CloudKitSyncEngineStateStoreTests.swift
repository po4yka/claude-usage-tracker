import CloudKit
import Foundation
@testable import HeimdallServices
import Testing

struct CloudKitSyncEngineStateStoreTests {
    @Test
    func inMemoryStoreRoundTrip() async throws {
        let store = InMemoryCloudKitSyncEngineStateStore()
        let loaded = try await store.loadState()
        #expect(loaded == nil)
    }

    @Test
    func inMemoryStorePurgeClearsState() async throws {
        let store = InMemoryCloudKitSyncEngineStateStore()
        try await store.purgeState()
        #expect(try await store.loadState() == nil)
    }

    @Test
    func fileBackedStoreReturnsNilWhenAbsent() async throws {
        let url = Self.tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = FileBackedCloudKitSyncEngineStateStore(fileURL: url)
        let loaded = try await store.loadState()
        #expect(loaded == nil)
    }

    @Test
    func fileBackedStorePurgeIsIdempotent() async throws {
        let url = Self.tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = FileBackedCloudKitSyncEngineStateStore(fileURL: url)
        try await store.purgeState()
        try await store.purgeState()
        #expect(try await store.loadState() == nil)
    }

    @Test
    func fileBackedDefaultURLIsUnderApplicationSupport() throws {
        let url = try FileBackedCloudKitSyncEngineStateStore.defaultURL(
            subdirectory: "HeimdallSyncTestsUnique",
            filename: "state.json"
        )
        defer {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        #expect(url.lastPathComponent == "state.json")
        #expect(url.deletingLastPathComponent().lastPathComponent == "HeimdallSyncTestsUnique")
        #expect(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
    }

    private static func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CloudKitSyncEngineStateStoreTests-\(UUID().uuidString).json")
    }
}
