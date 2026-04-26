import Foundation

// MARK: - Contract version namespaces

public enum LiveProviderContract {
    public static let version = 2
}

public enum LiveMonitorContract {
    public static let version = 2
}

public enum MobileSnapshotContract {
    public static let version = 1
}

public enum SyncedAggregateContract {
    public static let version = 1
}

// MARK: - Provider identity enums

public enum ProviderID: String, Codable, CaseIterable, Sendable, Identifiable {
    case claude
    case codex

    public var id: String { self.rawValue }
    public var title: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        }
    }
}

public enum MergeMenuTab: String, Codable, CaseIterable, Sendable, Identifiable {
    case overview
    case claude
    case codex

    public var id: String { self.rawValue }

    public var title: String {
        switch self {
        case .overview:
            return "Overview"
        case .claude:
            return "Claude"
        case .codex:
            return "Codex"
        }
    }

    public var providerID: ProviderID? {
        switch self {
        case .overview:
            return nil
        case .claude:
            return .claude
        case .codex:
            return .codex
        }
    }
}

// MARK: - Source / display preferences

public enum UsageSourcePreference: String, Codable, CaseIterable, Sendable {
    case auto
    case oauth
    case web
    case cli
}

public enum BrowserSource: String, Codable, CaseIterable, Sendable, Identifiable {
    case safari
    case chrome
    case arc
    case brave

    public var id: String { self.rawValue }

    public var title: String {
        switch self {
        case .safari:
            return "Safari"
        case .chrome:
            return "Chrome"
        case .arc:
            return "Arc"
        case .brave:
            return "Brave"
        }
    }
}

public enum ResetDisplayMode: String, Codable, CaseIterable, Sendable {
    case countdown
    case absolute
}

// MARK: - Per-provider and app-wide config

public struct ProviderConfig: Codable, Sendable {
    public var enabled: Bool
    public var source: UsageSourcePreference
    public var cookieSource: UsageSourcePreference
    public var dashboardExtrasEnabled: Bool

    public init(
        enabled: Bool = true,
        source: UsageSourcePreference = .auto,
        cookieSource: UsageSourcePreference = .auto,
        dashboardExtrasEnabled: Bool = false
    ) {
        self.enabled = enabled
        self.source = source
        self.cookieSource = cookieSource
        self.dashboardExtrasEnabled = dashboardExtrasEnabled
    }
}

public struct HeimdallBarConfig: Codable, Sendable {
    public var claude: ProviderConfig
    public var codex: ProviderConfig
    public var mergeIcons: Bool
    public var showUsedValues: Bool
    public var refreshIntervalSeconds: Int
    public var resetDisplayMode: ResetDisplayMode
    public var checkProviderStatus: Bool
    public var localNotificationsEnabled: Bool
    public var helperPort: Int

    public static let `default` = HeimdallBarConfig(
        claude: ProviderConfig(enabled: true, source: .oauth, cookieSource: .auto, dashboardExtrasEnabled: false),
        codex: ProviderConfig(enabled: true, source: .auto, cookieSource: .auto, dashboardExtrasEnabled: false),
        mergeIcons: true,
        showUsedValues: false,
        refreshIntervalSeconds: 300,
        resetDisplayMode: .countdown,
        checkProviderStatus: true,
        localNotificationsEnabled: false,
        helperPort: 8787
    )

    public init(
        claude: ProviderConfig,
        codex: ProviderConfig,
        mergeIcons: Bool,
        showUsedValues: Bool,
        refreshIntervalSeconds: Int,
        resetDisplayMode: ResetDisplayMode,
        checkProviderStatus: Bool,
        localNotificationsEnabled: Bool,
        helperPort: Int
    ) {
        self.claude = claude
        self.codex = codex
        self.mergeIcons = mergeIcons
        self.showUsedValues = showUsedValues
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.resetDisplayMode = resetDisplayMode
        self.checkProviderStatus = checkProviderStatus
        self.localNotificationsEnabled = localNotificationsEnabled
        self.helperPort = helperPort
    }

    enum CodingKeys: String, CodingKey {
        case claude
        case codex
        case mergeIcons = "merge_icons"
        case showUsedValues = "show_used_values"
        case refreshIntervalSeconds = "refresh_interval_seconds"
        case resetDisplayMode = "reset_display_mode"
        case checkProviderStatus = "check_provider_status"
        case localNotificationsEnabled = "local_notifications_enabled"
        case helperPort = "helper_port"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.claude = try container.decodeIfPresent(ProviderConfig.self, forKey: .claude) ?? HeimdallBarConfig.default.claude
        self.codex = try container.decodeIfPresent(ProviderConfig.self, forKey: .codex) ?? HeimdallBarConfig.default.codex
        self.mergeIcons = try container.decodeIfPresent(Bool.self, forKey: .mergeIcons) ?? HeimdallBarConfig.default.mergeIcons
        self.showUsedValues = try container.decodeIfPresent(Bool.self, forKey: .showUsedValues) ?? HeimdallBarConfig.default.showUsedValues
        self.refreshIntervalSeconds = try container.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? HeimdallBarConfig.default.refreshIntervalSeconds
        self.resetDisplayMode = try container.decodeIfPresent(ResetDisplayMode.self, forKey: .resetDisplayMode) ?? HeimdallBarConfig.default.resetDisplayMode
        self.checkProviderStatus = try container.decodeIfPresent(Bool.self, forKey: .checkProviderStatus) ?? HeimdallBarConfig.default.checkProviderStatus
        self.localNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .localNotificationsEnabled) ?? false
        self.helperPort = try container.decodeIfPresent(Int.self, forKey: .helperPort) ?? HeimdallBarConfig.default.helperPort
    }

    public func providerConfig(for provider: ProviderID) -> ProviderConfig {
        switch provider {
        case .claude: return self.claude
        case .codex: return self.codex
        }
    }
}
