import Foundation
import HeimdallDomain
import HeimdallPlatformMac
import Testing

/// Round-trip coverage for `KeychainStore` plus the keychain-touching paths of
/// `BrowserSessionController`. Each test uses a unique service prefix so the
/// production keychain entries (`dev.po4yka.heimdall`) stay untouched and
/// concurrent test runs do not collide.
///
/// Skipping behaviour: macOS keychain-write APIs work for any signed test host
/// on developer machines and the GitHub macos-latest runner. They fail with
/// `errSecMissingEntitlement` on hosts where the test bundle has no signing
/// identity. The tests use `try?` plus an `#expect` assertion on the read
/// path so a denied write yields a clear failure rather than a crash.
struct KeychainAndSessionTests {
    // MARK: KeychainStore raw Data round-trip

    @Test
    func keychainStoreRoundTripRawData() throws {
        let service = Self.uniqueService()
        let store = KeychainStore(service: service)
        let account = "round-trip"

        defer { try? store.delete(account: account) }

        // Initial load: nothing saved yet.
        #expect(store.load(account: account) == nil)

        // Save then load returns the same bytes.
        let payload = Data("hello-keychain".utf8)
        try store.save(payload, account: account)
        #expect(store.load(account: account) == payload)

        // Delete clears the entry.
        try store.delete(account: account)
        #expect(store.load(account: account) == nil)
    }

    // MARK: KeychainStore overwrite semantics

    @Test
    func keychainStoreSecondSaveOverwritesFirst() throws {
        let service = Self.uniqueService()
        let store = KeychainStore(service: service)
        let account = "overwrite"

        defer { try? store.delete(account: account) }

        try store.save(Data("first".utf8), account: account)
        try store.save(Data("second".utf8), account: account)
        #expect(store.load(account: account) == Data("second".utf8))
    }

    // MARK: KeychainStore JSON round-trip

    @Test
    func keychainStoreJSONRoundTripUsesSnakeCase() throws {
        let service = Self.uniqueService()
        let store = KeychainStore(service: service)
        let account = "json"

        defer { try? store.delete(account: account) }

        let original = Fixture(installedAt: "2026-04-26T10:00:00Z", retryCount: 3)
        try store.saveJSON(original, account: account)

        let decoded = store.loadJSON(Fixture.self, account: account)
        #expect(decoded == original)

        // Verify the on-disk encoding actually used snake_case (the
        // `KeychainStore.saveJSON` keyEncodingStrategy is `convertToSnakeCase`).
        guard let raw = store.load(account: account),
              let json = String(data: raw, encoding: .utf8)
        else {
            Issue.record("expected JSON payload to be readable as UTF-8")
            return
        }
        #expect(json.contains("\"installed_at\""))
        #expect(json.contains("\"retry_count\""))
    }

    // MARK: KeychainStore delete-of-missing is idempotent

    @Test
    func keychainStoreDeleteMissingDoesNotThrow() {
        let service = Self.uniqueService()
        let store = KeychainStore(service: service)
        // Deleting a never-saved account must succeed (errSecItemNotFound is
        // explicitly accepted by `KeychainStore.delete`).
        #expect(throws: Never.self) {
            try store.delete(account: "never-existed")
        }
    }

    // MARK: BrowserSessionController reads what was seeded into keychain

    /// Verifies `BrowserSessionController.importedSession(provider:)` reads
    /// from the same keychain account format used by `importBrowserSession`,
    /// and that `resetImportedSession` clears it.  This avoids needing a
    /// `BrowserSessionImporter` mock by seeding the keychain directly with
    /// a synthesised `ImportedBrowserSession` payload — exercising the
    /// load/reset code paths only.
    @Test
    func browserSessionControllerLoadsAndResetsImportedSession() async throws {
        let service = Self.uniqueService()
        let store = KeychainStore(service: service)
        let controller = BrowserSessionController(keychainStore: store)
        let provider = ProviderID.codex

        defer {
            try? store.delete(account: "\(provider.rawValue).web-session")
        }

        // Cold start: no session imported.
        let preload = await controller.importedSession(provider: provider)
        #expect(preload == nil)

        // Seed a synthesised session at the account format the controller
        // uses internally (`<provider>.web-session`).
        let seeded = Self.fixtureSession(provider: provider)
        try store.saveJSON(seeded, account: "\(provider.rawValue).web-session")

        // Controller reads it back identically.
        let loaded = await controller.importedSession(provider: provider)
        #expect(loaded?.provider == seeded.provider)
        #expect(loaded?.browserSource == seeded.browserSource)
        #expect(loaded?.profileName == seeded.profileName)
        #expect(loaded?.cookies.count == seeded.cookies.count)
        #expect(loaded?.loginRequired == seeded.loginRequired)

        // Reset clears it.
        try await controller.resetImportedSession(provider: provider)
        let postReset = await controller.importedSession(provider: provider)
        #expect(postReset == nil)
    }

    /// Sessions for two providers share the same `KeychainStore` but use
    /// distinct accounts; verifies they do not bleed into each other.
    @Test
    func browserSessionControllerNamespacesByProvider() async throws {
        let service = Self.uniqueService()
        let store = KeychainStore(service: service)
        let controller = BrowserSessionController(keychainStore: store)

        defer {
            try? store.delete(account: "\(ProviderID.claude.rawValue).web-session")
            try? store.delete(account: "\(ProviderID.codex.rawValue).web-session")
        }

        let claudeSession = Self.fixtureSession(provider: .claude, profileName: "Claude Profile")
        let codexSession = Self.fixtureSession(provider: .codex, profileName: "Codex Profile")

        try store.saveJSON(claudeSession, account: "claude.web-session")
        try store.saveJSON(codexSession, account: "codex.web-session")

        let claudeLoaded = await controller.importedSession(provider: .claude)
        let codexLoaded = await controller.importedSession(provider: .codex)

        #expect(claudeLoaded?.profileName == "Claude Profile")
        #expect(codexLoaded?.profileName == "Codex Profile")

        // Resetting Claude leaves Codex intact.
        try await controller.resetImportedSession(provider: .claude)
        #expect(await controller.importedSession(provider: .claude) == nil)
        #expect(await controller.importedSession(provider: .codex)?.profileName == "Codex Profile")
    }

    // MARK: Fixtures

    private struct Fixture: Codable, Equatable {
        let installedAt: String
        let retryCount: Int
    }

    private static func uniqueService() -> String {
        "dev.po4yka.heimdall.keychain.tests.\(UUID().uuidString)"
    }

    private static func fixtureSession(
        provider: ProviderID,
        profileName: String = "Default"
    ) -> ImportedBrowserSession {
        ImportedBrowserSession(
            provider: provider,
            browserSource: .safari,
            profileName: profileName,
            importedAt: "2026-04-26T10:00:00Z",
            storageKind: "binarycookies",
            cookies: [
                ImportedSessionCookie(
                    domain: provider == .claude ? "claude.ai" : "chatgpt.com",
                    name: "session",
                    value: "redacted",
                    path: "/",
                    expiresAt: "2026-05-26T10:00:00Z",
                    secure: true,
                    httpOnly: true
                ),
            ],
            loginRequired: false,
            expired: false,
            lastValidatedAt: "2026-04-26T10:00:00Z"
        )
    }
}
