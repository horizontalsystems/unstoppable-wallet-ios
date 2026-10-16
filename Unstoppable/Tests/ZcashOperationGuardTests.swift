import Foundation
import Testing
@testable import WalletCore

struct ZcashOperationGuardTests {
    @Test func lifecycleWaitsForSubmissionToFinish() async throws {
        let guardActor = ZcashOperationGuard()
        let order = OrderLog()

        let held = Latch()

        async let submission: Void = try guardActor.withSubmission(timeout: 5) {
            await order.append("submit-start")
            await held.open()
            try await Task.sleep(seconds: 0.2)
            await order.append("submit-end")
        }
        await held.wait()
        try await guardActor.withLifecycle(timeout: 5) { await order.append("lifecycle") }
        try await submission

        let entries = await order.entries
        #expect(entries == ["submit-start", "submit-end", "lifecycle"])
    }

    @Test func submissionGivesUpAfterTimeoutWhileLifecycleHolds() async throws {
        let guardActor = ZcashOperationGuard()

        let held = Latch()
        let release = Latch()

        // held until the submission has given up: a timed hold could end before the submission asks
        async let lifecycle: Void = try guardActor.withLifecycle(timeout: 5) {
            await held.open()
            await release.wait()
        }
        await held.wait()

        await #expect(throws: ZcashOperationGuard.Failure.self) {
            try await guardActor.withSubmission(timeout: 0.1) {}
        }
        await release.open()
        try await lifecycle
    }

    @Test func releasesOnThrow() async throws {
        let guardActor = ZcashOperationGuard()
        struct Boom: Error {}
        await #expect(throws: Boom.self) {
            try await guardActor.withSubmission(timeout: 1) { throw Boom() }
        }
        try await guardActor.withLifecycle(timeout: 0.1) {}
    }
}

// Waiting on a fixed sleep for the other task to take the guard is a race under a loaded test run;
// the body opens the latch once it is inside, and the test waits for that.
private actor Latch {
    private var isOpen = false

    func open() {
        isOpen = true
    }

    func wait() async {
        while !isOpen {
            try? await Task.sleep(seconds: 0.01)
        }
    }
}

private actor OrderLog {
    var entries: [String] = []

    func append(_ entry: String) {
        entries.append(entry)
    }
}
