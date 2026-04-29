import CloudKit
import Foundation
import HeimdallServices
import Testing

struct CloudKitRetryPolicyTests {
    @Test
    func successOnFirstAttemptDoesNotSleep() async throws {
        let sleepLog = SleepLog()
        var invocations = 0
        let result = try await withCloudKitRetry(
            policy: Self.fastPolicy,
            sleep: { nanoseconds in await sleepLog.record(nanoseconds) }
        ) { () -> Int in
            invocations += 1
            return 42
        }
        #expect(result == 42)
        #expect(invocations == 1)
        #expect(await sleepLog.count == 0)
    }

    @Test
    func succeedsAfterTransientRetryableError() async throws {
        let sleepLog = SleepLog()
        var invocations = 0
        let result = try await withCloudKitRetry(
            policy: Self.fastPolicy,
            sleep: { nanoseconds in await sleepLog.record(nanoseconds) }
        ) { () -> Int in
            invocations += 1
            if invocations < 2 {
                throw CKError(.networkFailure)
            }
            return 7
        }
        #expect(result == 7)
        #expect(invocations == 2)
        #expect(await sleepLog.count == 1)
    }

    @Test
    func nonRetryableErrorFailsImmediately() async {
        let sleepLog = SleepLog()
        var invocations = 0
        await #expect(throws: CKError.self) {
            _ = try await withCloudKitRetry(
                policy: Self.fastPolicy,
                sleep: { nanoseconds in await sleepLog.record(nanoseconds) }
            ) { () -> Int in
                invocations += 1
                throw CKError(.notAuthenticated)
            }
        }
        #expect(invocations == 1)
        #expect(await sleepLog.count == 0)
    }

    @Test
    func giveUpAfterMaxAttempts() async {
        let sleepLog = SleepLog()
        var invocations = 0
        await #expect(throws: CKError.self) {
            _ = try await withCloudKitRetry(
                policy: CloudKitRetryPolicy(
                    maxAttempts: 3,
                    baseDelayNanoseconds: 1,
                    maxDelayNanoseconds: 1,
                    jitterNanoseconds: 0
                ),
                sleep: { nanoseconds in await sleepLog.record(nanoseconds) }
            ) { () -> Int in
                invocations += 1
                throw CKError(.serviceUnavailable)
            }
        }
        #expect(invocations == 3)
        #expect(await sleepLog.count == 2)
    }

    @Test
    func retryAfterKeyOverridesExponentialBackoff() async throws {
        let sleepLog = SleepLog()
        var invocations = 0
        let expectedRetryDelayNanoseconds: UInt64 = 2_500_000_000
        let userInfo: [String: Any] = [CKErrorRetryAfterKey: 2.5]
        let error = CKError(_nsError: NSError(
            domain: CKErrorDomain,
            code: CKError.Code.requestRateLimited.rawValue,
            userInfo: userInfo
        ))
        _ = try await withCloudKitRetry(
            policy: CloudKitRetryPolicy(
                maxAttempts: 2,
                baseDelayNanoseconds: 1,
                maxDelayNanoseconds: 1,
                jitterNanoseconds: 0
            ),
            sleep: { nanoseconds in await sleepLog.record(nanoseconds) }
        ) { () -> Int in
            invocations += 1
            if invocations < 2 {
                throw error
            }
            return 9
        }
        #expect(invocations == 2)
        let recorded = await sleepLog.first
        #expect(recorded == expectedRetryDelayNanoseconds)
    }

    private static let fastPolicy = CloudKitRetryPolicy(
        maxAttempts: 3,
        baseDelayNanoseconds: 1,
        maxDelayNanoseconds: 1,
        jitterNanoseconds: 0
    )
}

private actor SleepLog {
    private(set) var recorded: [UInt64] = []

    func record(_ nanoseconds: UInt64) {
        self.recorded.append(nanoseconds)
    }

    var count: Int { self.recorded.count }
    var first: UInt64? { self.recorded.first }
}
