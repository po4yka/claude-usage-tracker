import Foundation
import Testing
@testable import HeimdallPlatformMac

struct MacPlatformFactoryTests {
    @Test
    func cloudKitSnapshotSyncIsDisabledForDerivedDebugBundles() {
        let derivedBundle = URL(fileURLWithPath: "/tmp/heimdall/.derived/Build/Products/Debug/HeimdallBar.app")

        #expect(!MacPlatformCompositionRoot.shouldEnableCloudKitSnapshotSync(bundleURL: derivedBundle))
    }

    @Test
    func cloudKitSnapshotSyncRemainsEnabledOutsideDerivedBundles() {
        let signedStyleBundle = URL(fileURLWithPath: "/Applications/HeimdallBar.app")

        #expect(MacPlatformCompositionRoot.shouldEnableCloudKitSnapshotSync(bundleURL: signedStyleBundle))
    }
}
