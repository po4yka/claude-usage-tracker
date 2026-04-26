import Foundation

public enum CloudSyncRole: String, Codable, CaseIterable, Sendable {
    case none
    case owner
    case participant
}

public enum CloudSyncStatus: String, Codable, CaseIterable, Sendable {
    case notConfigured = "not_configured"
    case ownerReady = "owner_ready"
    case inviteReady = "invite_ready"
    case participantJoined = "participant_joined"
    case iCloudUnavailable = "icloud_unavailable"
    case sharingBlocked = "sharing_blocked"
}

public struct CloudSyncSpaceState: Codable, Sendable, Equatable {
    public var role: CloudSyncRole
    public var status: CloudSyncStatus
    public var shareURL: String?
    public var zoneName: String?
    public var zoneOwnerName: String?
    public var lastPublishedAt: String?
    public var lastAcceptedAt: String?
    public var statusMessage: String?

    public init(
        role: CloudSyncRole = .none,
        status: CloudSyncStatus = .notConfigured,
        shareURL: String? = nil,
        zoneName: String? = nil,
        zoneOwnerName: String? = nil,
        lastPublishedAt: String? = nil,
        lastAcceptedAt: String? = nil,
        statusMessage: String? = nil
    ) {
        self.role = role
        self.status = status
        self.shareURL = shareURL
        self.zoneName = zoneName
        self.zoneOwnerName = zoneOwnerName
        self.lastPublishedAt = lastPublishedAt
        self.lastAcceptedAt = lastAcceptedAt
        self.statusMessage = statusMessage
    }

    public var isConfigured: Bool {
        switch self.status {
        case .ownerReady, .inviteReady, .participantJoined:
            return true
        case .notConfigured, .iCloudUnavailable, .sharingBlocked:
            return false
        }
    }

    enum CodingKeys: String, CodingKey {
        case role
        case status
        case shareURL = "share_url"
        case zoneName = "zone_name"
        case zoneOwnerName = "zone_owner_name"
        case lastPublishedAt = "last_published_at"
        case lastAcceptedAt = "last_accepted_at"
        case statusMessage = "status_message"
    }
}
