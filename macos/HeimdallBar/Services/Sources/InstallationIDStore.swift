import Foundation
import Security

public protocol InstallationIDPersisting: Sendable {
    func loadInstallationID() -> String?
    func saveInstallationID(_ installationID: String)
    func deleteInstallationID()
}

public final class KeychainInstallationIDStore: InstallationIDPersisting, @unchecked Sendable {
    public static let defaultService = "dev.heimdall.heimdallbar.sync"
    public static let defaultAccount = "installationID"
    public static let legacyUserDefaultsKey = "heimdallbar.cloud_sync.installation_id"

    private let service: String
    private let account: String
    private let legacyDefaults: UserDefaults?

    public init(
        service: String = KeychainInstallationIDStore.defaultService,
        account: String = KeychainInstallationIDStore.defaultAccount,
        legacyDefaults: UserDefaults? = .standard
    ) {
        self.service = service
        self.account = account
        self.legacyDefaults = legacyDefaults
    }

    public func loadInstallationID() -> String? {
        if let value = self.readKeychainValue() {
            return value
        }
        guard let legacy = self.legacyDefaults?.string(forKey: Self.legacyUserDefaultsKey),
              !legacy.isEmpty else {
            return nil
        }
        self.writeKeychainValue(legacy)
        self.legacyDefaults?.removeObject(forKey: Self.legacyUserDefaultsKey)
        return legacy
    }

    public func saveInstallationID(_ installationID: String) {
        self.writeKeychainValue(installationID)
        self.legacyDefaults?.removeObject(forKey: Self.legacyUserDefaultsKey)
    }

    public func deleteInstallationID() {
        let query = self.baseQuery()
        SecItemDelete(query as CFDictionary)
        self.legacyDefaults?.removeObject(forKey: Self.legacyUserDefaultsKey)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: self.account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
        ]
    }

    private func readKeychainValue() -> String? {
        var query = self.baseQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func writeKeychainValue(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query = self.baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            for (key, attributeValue) in attributes {
                addQuery[key] = attributeValue
            }
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}

public final class InMemoryInstallationIDStore: InstallationIDPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?

    public init(initialValue: String? = nil) {
        self.value = initialValue
    }

    public func loadInstallationID() -> String? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.value
    }

    public func saveInstallationID(_ installationID: String) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.value = installationID
    }

    public func deleteInstallationID() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.value = nil
    }
}
