import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNResponderTests {
    @Test func respondForwardsTopicIdAndResult() async throws {
        let client = WCNSpySignClient()
        let responder = WCNResponder(signClient: client)
        let parsed = try WCNTestFixtures.parsed()

        try await responder.respond(request: parsed, result: AnyCodable("0xsigned"))

        #expect(client.calls == [.init(topic: parsed.topic, requestId: parsed.id, response: .response(AnyCodable("0xsigned")))])
    }

    @Test func userRejectUsesCode5000() async throws {
        let client = WCNSpySignClient()
        let responder = WCNResponder(signClient: client)
        let parsed = try WCNTestFixtures.parsed()

        try await responder.reject(request: parsed, reason: .userRejected)

        #expect(client.calls.count == 1)
        #expect(client.calls[0].response == .error(JSONRPCError(code: 5000, message: "User rejected.")))
    }

    @Test func blockedCarriesReasonWithCode5000() async throws {
        let client = WCNSpySignClient()
        let responder = WCNResponder(signClient: client)
        let parsed = try WCNTestFixtures.parsed()

        try await responder.reject(request: parsed, reason: .blocked(reason: "to != 1inch router"))

        guard case let .error(error) = client.calls[0].response else {
            Issue.record("expected error response")
            return
        }
        #expect(error.code == 5000)
        #expect(error.message.contains("to != 1inch router"))
    }

    @Test func unsupportedMethodUsesCode5101() async throws {
        let client = WCNSpySignClient()
        let responder = WCNResponder(signClient: client)
        let parsed = try WCNTestFixtures.parsed()

        try await responder.reject(request: parsed, reason: .unsupportedMethod)

        #expect(client.calls[0].response == .error(JSONRPCError(code: 5101, message: "Unsupported wallet method.")))
    }

    @Test func clientErrorPropagates() async throws {
        let client = WCNSpySignClient()
        client.error = RelayDown()
        let responder = WCNResponder(signClient: client)
        let parsed = try WCNTestFixtures.parsed()

        await #expect(throws: RelayDown.self) {
            try await responder.respond(request: parsed, result: AnyCodable("x"))
        }
        #expect(client.calls.isEmpty)
    }
}

private struct RelayDown: Error {}
