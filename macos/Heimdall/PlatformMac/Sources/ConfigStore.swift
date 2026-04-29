import Foundation
import HeimdallDomain
import HeimdallServices

public final class ConfigStore: @unchecked Sendable, SettingsStore {
    public static let shared = ConfigStore()

    public let url: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(fileManager: FileManager = .default) {
        let base = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("heimdall", isDirectory: true)
        self.url = base.appendingPathComponent("config.json", isDirectory: false)
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    public func load() -> HeimdallConfig {
        guard let data = try? Data(contentsOf: self.url),
              let config = try? self.decoder.decode(HeimdallConfig.self, from: data) else {
            return .default
        }
        return config
    }

    public func save(_ config: HeimdallConfig) throws {
        try FileManager.default.createDirectory(
            at: self.url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        let data = try self.encoder.encode(config)
        try data.write(to: self.url, options: .atomic)
    }

    public func validate() throws {
        _ = self.load()
    }
}
