import Foundation
import Testing
@testable import HeimdallPlatformMac

struct MacPlatformFactoryTests {
    @Test
    func cloudKitSnapshotSyncIsDisabledForDerivedDebugBundles() {
        let derivedBundle = URL(fileURLWithPath: "/tmp/heimdall/.derived/Build/Products/Debug/Heimdall.app")

        #expect(!MacPlatformCompositionRoot.shouldEnableCloudKitSnapshotSync(bundleURL: derivedBundle))
    }

    @Test
    func cloudKitSnapshotSyncIsDisabledForManualDebugBuildProducts() {
        let debugBundle = URL(fileURLWithPath: "/tmp/heimdall-derived/Build/Products/Debug/Heimdall.app")

        #expect(!MacPlatformCompositionRoot.shouldEnableCloudKitSnapshotSync(bundleURL: debugBundle))
    }

    @Test
    func cloudKitSnapshotSyncRemainsEnabledOutsideDerivedBundles() {
        let signedStyleBundle = URL(fileURLWithPath: "/Applications/Heimdall.app")

        #expect(MacPlatformCompositionRoot.shouldEnableCloudKitSnapshotSync(bundleURL: signedStyleBundle))
    }

    @Test
    func userNotificationsAreDisabledForDerivedDebugBundles() {
        let derivedBundle = URL(fileURLWithPath: "/tmp/heimdall/.derived/Build/Products/Debug/Heimdall.app")

        #expect(!MacPlatformCompositionRoot.shouldEnableUserNotifications(bundleURL: derivedBundle))
    }

    @Test
    func userNotificationsAreDisabledForManualDebugBuildProducts() {
        let debugBundle = URL(fileURLWithPath: "/tmp/heimdall-derived/Build/Products/Debug/Heimdall.app")

        #expect(!MacPlatformCompositionRoot.shouldEnableUserNotifications(bundleURL: debugBundle))
    }

    @Test
    func userNotificationsRemainEnabledOutsideDerivedBundles() {
        let signedStyleBundle = URL(fileURLWithPath: "/Applications/Heimdall.app")

        #expect(MacPlatformCompositionRoot.shouldEnableUserNotifications(bundleURL: signedStyleBundle))
    }
}
