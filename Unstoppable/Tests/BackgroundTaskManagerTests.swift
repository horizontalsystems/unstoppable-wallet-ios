import Combine
import Testing
@testable import WalletCore
import ZcashLightClientKit

@MainActor
struct BackgroundTaskManagerTests {
    @Test func criticalSectionActivatesAndCompletes() async throws {
        let manager = BackgroundTaskManager()
        #expect(!manager.isCriticalActive)

        try await manager.performCritical(name: "test") {
            #expect(manager.isCriticalActive)
        }

        #expect(!manager.isCriticalActive)
    }

    @Test func nestedSectionsStayActiveUntilLastEnds() async throws {
        let manager = BackgroundTaskManager()

        try await manager.performCritical(name: "outer") {
            try await manager.performCritical(name: "inner") {
                #expect(manager.isCriticalActive)
            }
            #expect(manager.isCriticalActive) // inner ended, outer still holds
        }

        #expect(!manager.isCriticalActive)
    }

    @Test func completedPublisherFiresOnceAfterLastSection() async throws {
        let manager = BackgroundTaskManager()
        var completions = 0
        let cancellable = manager.criticalCompletedPublisher.sink { completions += 1 }

        try await manager.performCritical(name: "outer") {
            try await manager.performCritical(name: "inner") {}
        }

        #expect(completions == 1)
        cancellable.cancel()
    }

    @Test func throwingOperationStillEndsSection() async throws {
        struct TestError: Error {}
        let manager = BackgroundTaskManager()

        do {
            try await manager.performCritical(name: "failing") {
                throw TestError()
            }
            Issue.record("expected throw")
        } catch {}

        #expect(!manager.isCriticalActive)
    }

    @Test func operationResultIsReturned() async throws {
        let manager = BackgroundTaskManager()

        let value = try await manager.performCritical(name: "value") { 42 }
        #expect(value == 42)
    }
}

struct ZcashResubmissionCandidateTests {
    @Test func pendingSentTransactionIsCandidate() {
        let candidate = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 1100, latestHeight: 1000)
        #expect(candidate)
    }

    @Test func minedTransactionIsNotCandidate() {
        let candidate = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: 900, hasRaw: true, expiryHeight: 1100, latestHeight: 1000)
        #expect(!candidate)
    }

    @Test func receivedTransactionIsNotCandidate() {
        let candidate = ZcashAdapter.isResubmissionCandidate(isSentTransaction: false, minedHeight: nil, hasRaw: true, expiryHeight: 1100, latestHeight: 1000)
        #expect(!candidate)
    }

    @Test func expiredTransactionIsNotCandidate() {
        let candidate = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 1000, latestHeight: 1000)
        #expect(!candidate)
    }

    @Test func missingRawIsNotCandidate() {
        let candidate = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: false, expiryHeight: 1100, latestHeight: 1000)
        #expect(!candidate)
    }

    @Test func noExpiryIsNotCandidate() {
        let nilExpiry = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: nil, latestHeight: 1000)
        let zeroExpiry = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 0, latestHeight: 1000)
        #expect(!nilExpiry)
        #expect(!zeroExpiry)
    }

    @Test func staleZeroHeightKeepsCandidate() {
        // synchronizer not started yet: latestState is .zero — do not drop candidates on unknown height
        let candidate = ZcashAdapter.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 500, latestHeight: 0)
        #expect(candidate)
    }
}
