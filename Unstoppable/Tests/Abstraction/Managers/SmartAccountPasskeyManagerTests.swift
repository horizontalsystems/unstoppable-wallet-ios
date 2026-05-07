import AuthenticationServices
import Foundation
import Testing
@testable import Unstoppable

struct SmartAccountPasskeyManagerTests {
    @Test func registerRejectsReentryWhileInFlight() async throws {
        let requester = FakeRequester()
        let manager = SmartAccountPasskeyManager(requester: requester)

        let firstTask = Task { try? await manager.register(name: "first") }
        try await waitForInvocations(requester, count: 1)

        await #expect(throws: SmartAccountPasskeyManager.AAError.busy) {
            try await manager.register(name: "second")
        }
        #expect(requester.invocations == 1)

        firstTask.cancel()
    }

    @Test func assertForSigningRejectsReentryWhileInFlight() async throws {
        let requester = FakeRequester()
        let manager = SmartAccountPasskeyManager(requester: requester)

        let firstTask = Task { try? await manager.register(name: "first") }
        try await waitForInvocations(requester, count: 1)

        await #expect(throws: SmartAccountPasskeyManager.AAError.busy) {
            try await manager.assertForSigning(
                credentialID: Data([0xCC]),
                challenge: Data(repeating: 0x01, count: 32)
            )
        }
        #expect(requester.invocations == 1)

        firstTask.cancel()
    }

    private func waitForInvocations(_ requester: FakeRequester, count: Int) async throws {
        for _ in 0 ..< 200 {
            if requester.invocations >= count { return }
            await Task.yield()
        }
        Issue.record("Requester never reached \(count) invocations (saw \(requester.invocations))")
    }
}

private final class FakeRequester: PasskeyAuthorizationRequesting, @unchecked Sendable {
    private(set) var invocations: Int = 0

    func perform(
        requests _: [ASAuthorizationRequest],
        delegate _: ASAuthorizationControllerDelegate,
        contextProvider _: ASAuthorizationControllerPresentationContextProviding
    ) {
        invocations += 1
        // Intentionally do nothing else — keeps the continuation pending so reentry is observable.
    }
}
