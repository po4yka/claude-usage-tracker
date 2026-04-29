import Foundation
import HeimdallServices
import Testing

struct InstallationIDStoreTests {
    @Test
    func inMemoryStoreRoundTrip() {
        let store = InMemoryInstallationIDStore()

        #expect(store.loadInstallationID() == nil)

        store.saveInstallationID("installation-1")
        #expect(store.loadInstallationID() == "installation-1")

        store.saveInstallationID("installation-2")
        #expect(store.loadInstallationID() == "installation-2")

        store.deleteInstallationID()
        #expect(store.loadInstallationID() == nil)
    }

    @Test
    func inMemoryStoreAcceptsInitialValue() {
        let store = InMemoryInstallationIDStore(initialValue: "seed")
        #expect(store.loadInstallationID() == "seed")
    }

    @Test
    func keychainStoreRoundTripSurvivesNewInstance() {
        let service = Self.uniqueService()
        let legacyDefaults = UserDefaults(suiteName: Self.uniqueDefaultsSuite())!

        let writer = KeychainInstallationIDStore(service: service, legacyDefaults: legacyDefaults)
        writer.deleteInstallationID()
        defer { writer.deleteInstallationID() }

        writer.saveInstallationID("device-abc")

        let reader = KeychainInstallationIDStore(service: service, legacyDefaults: legacyDefaults)
        #expect(reader.loadInstallationID() == "device-abc")
    }

    @Test
    func keychainStoreMigratesLegacyUserDefaultsValueOnFirstLoad() {
        let service = Self.uniqueService()
        let suiteName = Self.uniqueDefaultsSuite()
        let legacyDefaults = UserDefaults(suiteName: suiteName)!
        legacyDefaults.set("legacy-id", forKey: KeychainInstallationIDStore.legacyUserDefaultsKey)

        let store = KeychainInstallationIDStore(service: service, legacyDefaults: legacyDefaults)
        store.deleteInstallationID()
        legacyDefaults.set("legacy-id", forKey: KeychainInstallationIDStore.legacyUserDefaultsKey)
        defer {
            store.deleteInstallationID()
            UserDefaults().removePersistentDomain(forName: suiteName)
        }

        let migrated = store.loadInstallationID()
        #expect(migrated == "legacy-id")
        #expect(legacyDefaults.string(forKey: KeychainInstallationIDStore.legacyUserDefaultsKey) == nil)

        let reread = store.loadInstallationID()
        #expect(reread == "legacy-id")
    }

    @Test
    func keychainStoreSaveClearsLegacyKey() {
        let service = Self.uniqueService()
        let suiteName = Self.uniqueDefaultsSuite()
        let legacyDefaults = UserDefaults(suiteName: suiteName)!
        legacyDefaults.set("stale", forKey: KeychainInstallationIDStore.legacyUserDefaultsKey)

        let store = KeychainInstallationIDStore(service: service, legacyDefaults: legacyDefaults)
        defer {
            store.deleteInstallationID()
            UserDefaults().removePersistentDomain(forName: suiteName)
        }

        store.saveInstallationID("fresh-id")

        #expect(legacyDefaults.string(forKey: KeychainInstallationIDStore.legacyUserDefaultsKey) == nil)
        #expect(store.loadInstallationID() == "fresh-id")
    }

    private static func uniqueService() -> String {
        "dev.po4yka.heimdall.sync.tests.\(UUID().uuidString)"
    }

    private static func uniqueDefaultsSuite() -> String {
        "InstallationIDStoreTests.\(UUID().uuidString)"
    }
}
