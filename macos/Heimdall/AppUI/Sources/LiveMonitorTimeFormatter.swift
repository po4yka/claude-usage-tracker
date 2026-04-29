import Foundation

/// Parses an ISO 8601 timestamp emitted by the heimdall helper (which always
/// includes fractional seconds, e.g. "2026-04-25T06:11:40.607239+00:00") and
/// returns a short time string like "6:11 AM".
///
/// Falls back to the raw string if both parse attempts fail. Both the
/// fractional-seconds path and the canonical no-fractional path are tried so
/// the helper tolerates any ISO 8601 string the server might send.
func liveMonitorShortTime(_ iso: String) -> String {
    if let date = try? Date(iso, strategy: .iso8601
        .year().month().day()
        .time(includingFractionalSeconds: true)
        .timeZone(separator: .colon)) {
        return date.formatted(date: .omitted, time: .shortened)
    }
    if let date = try? Date(iso, strategy: .iso8601) {
        return date.formatted(date: .omitted, time: .shortened)
    }
    return iso
}

/// Parses an ISO 8601 timestamp and returns an abbreviated date + short time.
/// Used for less time-sensitive labels (e.g. "Apr 25, 2026 6:11 AM").
func liveMonitorAbbreviatedTimestamp(_ iso: String) -> String {
    if let date = try? Date(iso, strategy: .iso8601
        .year().month().day()
        .time(includingFractionalSeconds: true)
        .timeZone(separator: .colon)) {
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    if let date = try? Date(iso, strategy: .iso8601) {
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    return iso
}
