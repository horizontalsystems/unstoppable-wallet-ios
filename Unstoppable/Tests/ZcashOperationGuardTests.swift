import Foundation
import Testing
@testable import WalletCore

struct ZcashOperationGuardTests {
    @Test func lifecycleWaitsForSubmissionToFinish() async throws {
        let guardActor = ZcashOperationGuard()
        let order = OrderLog()

        async let submission: Void = try guardActor.withSubmission(timeout: 5) {
            await order.append("submit-start")
            try await Task.sleep(seconds: 0.2)
            await order.append("submit-end")
        }
        try await Task.sleep(seconds: 0.05)
        try await guardActor.withLifecycle(timeout: 5) { await order.append("lifecycle") }
        try await submission

        let entries = await order.entries
        #expect(entries == ["submit-start", "submit-end", "lifecycle"])
    }

    @Test func submissionGivesUpAfterTimeoutWhileLifecycleHolds() async throws {
        let guardActor = ZcashOperationGuard()

        async let lifecycle: Void = try guardActor.withLifecycle(timeout: 5) { try await Task.sleep(seconds: 0.5) }
        try await Task.sleep(seconds: 0.05)

        await #expect(throws: ZcashOperationGuard.Failure.self) {
            try await guardActor.withSubmission(timeout: 0.1) {}
        }
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

private actor OrderLog {
    var entries: [String] = []

    func append(_ entry: String) {
        entries.append(entry)
    }
}
