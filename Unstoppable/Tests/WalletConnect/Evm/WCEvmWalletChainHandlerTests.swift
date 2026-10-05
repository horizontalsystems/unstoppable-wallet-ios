import Testing
import WalletConnectSign
@testable import WalletCore

struct WCEvmWalletChainHandlerTests {
    private let client = WCSpySignClient()
    private let resolver = StubChainResolver(known: [1, 10])

    private func handler() -> WCEvmWalletChainHandler {
        WCEvmWalletChainHandler(chainResolver: resolver, responder: WCResponder(signClient: client))
    }

    private func request(targetChainId: Int, verdict: WCVerificationVerdict = .pass) throws -> WCRequest {
        let request = try WCTestFixtures.request(method: WCEvmWalletChainPayload.switchMethod)
        return WCRequest(payload: WCEvmWalletChainPayload(request: request, targetChainId: targetChainId), verdict: verdict, dAppName: "dApp")
    }

    private var session: WCSessionInfo {
        WCSessionInfo(topic: WCTestFixtures.topic, accountId: "account-1", dAppName: "dApp", approvedAccounts: [WCTestFixtures.approvedMainnet, WCTestFixtures.approvedOptimism])
    }

    @Test func approvedKnownChainIsAcknowledged() async throws {
        try await handler().respond(request: request(targetChainId: 10), session: session)

        #expect(client.calls.count == 1)
        #expect(client.calls[0].response == .response(AnyCodable("null")))
    }

    @Test func chainOutsideSessionIsUnrecognized() async throws {
        resolver.known.insert(56)
        try await handler().respond(request: request(targetChainId: 56), session: session)
        #expect(client.calls[0].response == .error(JSONRPCError(code: 4902, message: "Unrecognized chain ID")))
    }

    @Test func unknownChainIsUnrecognizedEvenIfApproved() async throws {
        resolver.known = [1]
        try await handler().respond(request: request(targetChainId: 10), session: session)
        #expect(client.calls[0].response == .error(JSONRPCError(code: 4902, message: "Unrecognized chain ID")))
    }

    @Test func blockedVerdictIsRejected() async throws {
        try await handler().respond(request: request(targetChainId: 10, verdict: .block(reason: .originScam)), session: session)
        guard case let .error(error) = client.calls[0].response else {
            Issue.record("expected error response")
            return
        }
        #expect(error.code == 5000)
    }

    @Test func handlesOnlyWalletChainPayloads() throws {
        let walletChain = try request(targetChainId: 1).payload
        let other = try WCStubRequestPayload.make()
        #expect(handler().handles(walletChain))
        #expect(handler().handles(other) == false)
    }
}

private final class StubChainResolver: IWCEvmChainResolver {
    var known: Set<Int>

    init(known: Set<Int>) {
        self.known = known
    }

    func isKnown(chainId: Int) -> Bool {
        known.contains(chainId)
    }
}
