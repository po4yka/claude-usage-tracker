import CloudKit
import Foundation

public struct CloudKitRetryPolicy: Sendable {
    public var maxAttempts: Int
    public var baseDelayNanoseconds: UInt64
    public var maxDelayNanoseconds: UInt64
    public var jitterNanoseconds: UInt64

    public init(
        maxAttempts: Int = 3,
        baseDelayNanoseconds: UInt64 = 1_000_000_000,
        maxDelayNanoseconds: UInt64 = 8_000_000_000,
        jitterNanoseconds: UInt64 = 100_000_000
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelayNanoseconds = baseDelayNanoseconds
        self.maxDelayNanoseconds = maxDelayNanoseconds
        self.jitterNanoseconds = jitterNanoseconds
    }

    public static let `default` = CloudKitRetryPolicy()

    public static func isRetryable(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        switch ckError.code {
        case .networkUnavailable,
             .networkFailure,
             .serviceUnavailable,
             .requestRateLimited,
             .zoneBusy:
            return true
        default:
            return false
        }
    }

    public static func retryAfterNanoseconds(_ error: Error) -> UInt64? {
        guard let ckError = error as? CKError else { return nil }
        let userInfo = ckError.userInfo
        if let seconds = userInfo[CKErrorRetryAfterKey] as? Double, seconds > 0 {
            return UInt64(seconds * 1_000_000_000)
        }
        if let number = userInfo[CKErrorRetryAfterKey] as? NSNumber {
            let seconds = number.doubleValue
            return seconds > 0 ? UInt64(seconds * 1_000_000_000) : nil
        }
        return nil
    }

    func delayForAttempt(_ attempt: Int, serverRetryAfter: UInt64?) -> UInt64 {
        if let serverRetryAfter {
            return serverRetryAfter
        }
        let exponent = max(attempt - 1, 0)
        let scaled = self.baseDelayNanoseconds &<< exponent
        let bounded = min(scaled, self.maxDelayNanoseconds)
        let jitter: UInt64 = self.jitterNanoseconds == 0 ? 0 : UInt64.random(in: 0...self.jitterNanoseconds)
        return bounded &+ jitter
    }
}

public func withCloudKitRetry<T: Sendable>(
    policy: CloudKitRetryPolicy = .default,
    sleep: @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
    operation: () async throws -> T
) async throws -> T {
    var attempt = 0
    while true {
        do {
            return try await operation()
        } catch {
            attempt += 1
            guard attempt < policy.maxAttempts, CloudKitRetryPolicy.isRetryable(error) else {
                throw error
            }
            let delay = policy.delayForAttempt(
                attempt,
                serverRetryAfter: CloudKitRetryPolicy.retryAfterNanoseconds(error)
            )
            try await sleep(delay)
        }
    }
}
