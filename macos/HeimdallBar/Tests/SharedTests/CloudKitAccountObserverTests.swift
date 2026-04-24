import CloudKit
import Foundation
import HeimdallServices
import Testing

struct CloudKitAccountObserverTests {
    @Test
    func observerInvokesHandlerOnAccountChangedNotification() async {
        let center = NotificationCenter()
        let counter = InvocationCounter()
        let observer = CloudKitAccountObserver(notificationCenter: center) {
            counter.increment()
        }
        observer.start()

        center.post(name: .CKAccountChanged, object: nil)
        center.post(name: .CKAccountChanged, object: nil)

        await Self.waitForMainRunLoop()
        #expect(counter.value == 2)
    }

    @Test
    func stopPreventsFurtherInvocations() async {
        let center = NotificationCenter()
        let counter = InvocationCounter()
        let observer = CloudKitAccountObserver(notificationCenter: center) {
            counter.increment()
        }
        observer.start()
        center.post(name: .CKAccountChanged, object: nil)
        await Self.waitForMainRunLoop()
        #expect(counter.value == 1)

        observer.stop()
        center.post(name: .CKAccountChanged, object: nil)
        await Self.waitForMainRunLoop()
        #expect(counter.value == 1)
    }

    @Test
    func startIsIdempotent() async {
        let center = NotificationCenter()
        let counter = InvocationCounter()
        let observer = CloudKitAccountObserver(notificationCenter: center) {
            counter.increment()
        }
        observer.start()
        observer.start()
        observer.start()

        center.post(name: .CKAccountChanged, object: nil)
        await Self.waitForMainRunLoop()
        #expect(counter.value == 1)
    }

    private static func waitForMainRunLoop() async {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

private final class InvocationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.count += 1
    }

    var value: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.count
    }
}
