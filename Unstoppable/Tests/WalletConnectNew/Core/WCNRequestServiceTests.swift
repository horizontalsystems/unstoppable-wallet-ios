import ReownWalletKit
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNRequestServiceTests {
    private let client = WCNSpySignClient()
    private let parsers = WCNParserRegistry()
    private let verifiers = WCNVerifierRegistry()

    private var session: WCNSessionInfo {
        WCNSessionInfo(topic: WCNTestFixtures.topic, accountId: "account-1", dAppName: "React App", approvedAccounts: [WCNTestFixtures.approvedMainnet])
    }

    private func service() -> WCNRequestService {
        WCNRequestService(parsers: parsers, verifiers: verifiers, responder: WCNResponder(signClient: client))
    }

    @Test func passingTransactionYieldsSendData() async throws {
        parsers.register(StubParser(kind: .transaction, sendData: .zcashMigration))
        let request = try WCNTestFixtures.request()

        let outcome = await service().process(request: request, context: nil, session: session)

        guard case let .transaction(wcnRequest, sendData) = outcome else {
            Issue.record("expected transaction outcome")
            return
        }
        #expect(wcnRequest.verdict == .pass)
        #expect(wcnRequest.dAppName == "React App")
        guard case let .walletConnectNew(inner, carried) = sendData else {
            Issue.record("expected walletConnectNew send data")
            return
        }
        #expect(inner != nil)
        #expect(carried.payload.id == request.id)
        #expect(client.calls.isEmpty)
    }

    @Test func blockedTransactionIsNotAnsweredYet() async throws {
        parsers.register(StubParser(kind: .transaction, sendData: nil))
        verifiers.register(StubVerifier(verdict: .block(reason: .swapNotToCanonicalRouter)))

        let request = try WCNTestFixtures.request()
        let outcome = await service().process(request: request, context: nil, session: session)

        guard case let .transaction(wcnRequest, _) = outcome else {
            Issue.record("expected transaction outcome")
            return
        }
        #expect(wcnRequest.isBlocked)
        #expect(client.calls.isEmpty)
    }

    @Test func signMessageAndDirectBranch() async throws {
        parsers.register(StubParser(kind: .signMessage, sendData: nil, method: "personal_sign"))
        parsers.register(StubParser(kind: .direct, sendData: nil, method: "wallet_switchEthereumChain"))

        let signRequest = try WCNTestFixtures.request(method: "personal_sign")
        let directRequest = try WCNTestFixtures.request(method: "wallet_switchEthereumChain")
        let sign = await service().process(request: signRequest, context: nil, session: session)
        let direct = await service().process(request: directRequest, context: nil, session: session)

        guard case .signMessage = sign else {
            Issue.record("expected signMessage outcome")
            return
        }
        guard case .direct = direct else {
            Issue.record("expected direct outcome")
            return
        }
    }

    @Test func unsupportedMethodIsRejectedWith5101() async throws {
        let request = try WCNTestFixtures.request(method: "eth_unknown")

        let outcome = await service().process(request: request, context: nil, session: session)

        guard case .rejected(.unsupportedMethod) = outcome else {
            Issue.record("expected rejected outcome")
            return
        }
        #expect(client.calls.count == 1)
        #expect(client.calls[0].requestId == request.id)
        #expect(client.calls[0].response == .error(JSONRPCError(code: 5101, message: "Unsupported wallet method.")))
    }

    @Test func malformedParamsAreRejectedWithInvalidParams() async throws {
        parsers.register(StubParser(kind: .transaction, sendData: nil, error: StubParser.Malformed()))

        let request = try WCNTestFixtures.request()
        let outcome = await service().process(request: request, context: nil, session: session)

        guard case .rejected(.invalidParams) = outcome else {
            Issue.record("expected rejected outcome")
            return
        }
        guard case let .error(error) = client.calls[0].response else {
            Issue.record("expected error response")
            return
        }
        #expect(error.code == -32602)
    }

    @Test func relayFailureDuringRejectStillYieldsRejected() async throws {
        client.error = RelayDown()

        let request = try WCNTestFixtures.request(method: "eth_unknown")
        let outcome = await service().process(request: request, context: nil, session: session)

        guard case .rejected = outcome else {
            Issue.record("expected rejected outcome")
            return
        }
        #expect(client.calls.isEmpty)
    }

    @Test func verifiersReceiveSessionAndOriginContext() async throws {
        parsers.register(StubParser(kind: .transaction, sendData: nil))
        let verifier = StubVerifier(verdict: .pass)
        verifiers.register(verifier)
        let verifyContext = VerifyContext(origin: "https://react-app.walletconnect.com", validation: .valid)

        let request = try WCNTestFixtures.request()
        _ = await service().process(request: request, context: verifyContext, session: session)

        let received = try #require(verifier.receivedContext)
        #expect(received.accountId == "account-1")
        #expect(received.approvedAccounts == [WCNTestFixtures.approvedMainnet])
        #expect(received.verifyContext?.origin == "https://react-app.walletconnect.com")
    }
}

private final class StubParser: IWCNParser {
    struct Malformed: Error {}

    private let kind: WCNRequestPayload.Kind
    private let sendData: SendData?
    private let method: String
    private let error: Error?

    init(kind: WCNRequestPayload.Kind, sendData: SendData?, method: String = "eth_sendTransaction", error: Error? = nil) {
        self.kind = kind
        self.sendData = sendData
        self.method = method
        self.error = error
    }

    func parse(request: Request) throws -> WCNRequestPayload? {
        guard request.method == method else { return nil }
        if let error { throw error }
        return StubPayload(request: request, kind: kind, sendData: sendData)
    }
}

private final class StubPayload: WCNRequestPayload {
    private let sendData: SendData?

    init(request: Request, kind: WCNRequestPayload.Kind, sendData: SendData?) {
        self.sendData = sendData
        super.init(request: request, kind: kind, from: WCNTestFixtures.address)
    }

    override func makeSendData() -> SendData? { sendData }
}

private final class StubVerifier: IWCNVerifier {
    private let verdict: WCNVerificationVerdict
    private(set) var receivedContext: WCNVerificationContext?

    init(verdict: WCNVerificationVerdict) {
        self.verdict = verdict
    }

    func handles(_: WCNVerificationContext) -> Bool { true }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        receivedContext = context
        return verdict
    }
}

private struct RelayDown: Error {}
