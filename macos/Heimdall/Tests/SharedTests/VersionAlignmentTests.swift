import Foundation
import Testing

struct VersionAlignmentTests {
    @Test
    func cargoVersionMatchesHeimdallMarketingVersion() throws {
        let cargo = try FixtureLoader.string("Cargo.toml")
        let project = try FixtureLoader.string("macos/Heimdall/project.yml")
        let pbxproj = try FixtureLoader.string("macos/Heimdall/Heimdall.xcodeproj/project.pbxproj")
        let appInfo = try FixtureLoader.string("macos/Heimdall/App/Info.plist")
        let widgetInfo = try FixtureLoader.string("macos/Heimdall/Widget/Info.plist")
        let appEntitlements = try FixtureLoader.string("macos/Heimdall/App/Heimdall.entitlements")
        let widgetEntitlements = try FixtureLoader.string("macos/Heimdall/Widget/HeimdallWidget.entitlements")

        let cargoVersion = try #require(Self.firstMatch(in: cargo, pattern: #"(?m)^version\s*=\s*"([^"]+)""#))
        let marketingVersion = try #require(Self.firstMatch(in: project, pattern: #"(?m)^\s*MARKETING_VERSION:\s*([^\s]+)\s*$"#))

        #expect(marketingVersion == cargoVersion)
        #expect(pbxproj.contains("MARKETING_VERSION = \(cargoVersion);"))
        #expect(appInfo.contains("$(MARKETING_VERSION)"))
        #expect(appInfo.contains("$(CURRENT_PROJECT_VERSION)"))
        #expect(widgetInfo.contains("$(MARKETING_VERSION)"))
        #expect(widgetInfo.contains("$(CURRENT_PROJECT_VERSION)"))
        #expect(appEntitlements.contains("group.dev.po4yka.heimdall"))
        #expect(widgetEntitlements.contains("group.dev.po4yka.heimdall"))
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }
}
