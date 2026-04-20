import Foundation

public enum WidgetSnapshotStore {
    public static let appGroupID = "group.dev.heimdall.heimdallbar"
    private static let filename = "widget-snapshot.json"

    public static func save(_ snapshot: WidgetSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(snapshot)
        let url = try self.snapshotURL(createDirectory: true)
        try data.write(to: url, options: .atomic)
    }

    public static func load() -> WidgetSnapshot? {
        guard let url = try? self.snapshotURL(createDirectory: false),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    private static func snapshotURL(createDirectory: Bool) throws -> URL {
        let fm = FileManager.default
        let base = fm.containerURL(forSecurityApplicationGroupIdentifier: self.appGroupID)
            ?? fm.homeDirectoryForCurrentUser
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("HeimdallBar", isDirectory: true)
        if createDirectory {
            try fm.createDirectory(at: base, withIntermediateDirectories: true, attributes: nil)
        }
        return base.appendingPathComponent(self.filename, isDirectory: false)
    }
}
