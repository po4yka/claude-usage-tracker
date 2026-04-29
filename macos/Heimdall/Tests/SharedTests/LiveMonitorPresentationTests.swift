import Foundation
import Testing
@testable import HeimdallAppUI

struct WindowHeaderIssuePresentationTests {
    @Test
    func nilMessageProducesNoPresentation() {
        #expect(WindowHeaderIssuePresentation.make(message: nil) == nil)
    }

    @Test
    func helperStartingMessageMapsToPendingTone() {
        let presentation = WindowHeaderIssuePresentation.make(
            message: "The local Heimdall server is still starting."
        )
        #expect(presentation?.tone == .pending)
        #expect(presentation?.badge == "Local server")
        #expect(presentation?.title == "Starting local server")
    }

    @Test
    func connectionRefusedMessageMapsToWarningWithLocalServerBadge() {
        let presentation = WindowHeaderIssuePresentation.make(
            message: "Cannot reach the local Heimdall server (connection refused)."
        )
        #expect(presentation?.tone == .warning)
        #expect(presentation?.badge == "Local server")
        #expect(presentation?.title == "Can\u{2019}t reach Heimdall")
    }

    @Test
    func timeoutMessageMapsToWarningWithLongRespondTitle() {
        let presentation = WindowHeaderIssuePresentation.make(
            message: "The helper did not respond in time."
        )
        #expect(presentation?.tone == .warning)
        #expect(presentation?.badge == "Local server")
        #expect(presentation?.title == "Heimdall is taking too long to respond")
    }

    @Test
    func unknownMessageFallsBackToRefreshIssueBadge() {
        let presentation = WindowHeaderIssuePresentation.make(
            message: "Some unknown error"
        )
        #expect(presentation?.tone == .warning)
        #expect(presentation?.badge == "Refresh issue")
    }
}

struct LiveMonitorShortTimeTests {
    @Test
    func parsesISO8601WithFractionalSeconds() {
        let raw = "2026-04-25T06:11:40.607239+00:00"
        let result = liveMonitorShortTime(raw)
        #expect(!result.contains("T"))
        #expect(!result.contains("607239"))
        #expect(result != raw)
    }

    @Test
    func parsesCanonicalISO8601WithoutFractionalSeconds() {
        let result = liveMonitorShortTime("2026-04-25T06:11:40Z")
        #expect(!result.contains("T"))
        #expect(result != "2026-04-25T06:11:40Z")
    }

    @Test
    func returnsRawStringWhenUnparseable() {
        #expect(liveMonitorShortTime("not-a-date") == "not-a-date")
    }

    @Test
    func abbreviatedTimestampParsesFractionalSeconds() {
        let result = liveMonitorAbbreviatedTimestamp("2026-04-25T06:11:40.607239+00:00")
        #expect(!result.contains("T"))
        #expect(!result.contains("607239"))
    }
}
