import BigInt
import Combine
import Foundation
import ReownWalletKit
import WalletConnectUtils
@testable import WalletCore

enum WCNTestFixtures {
    static let topic = "aa686b420fd4a0091c750575b8888c68405159ac0bb220fb34b334f48f9f2d3f"
    static let address = "0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d"

    static func request(method: String = "eth_sendTransaction", chainId: String = "eip155:1", params: AnyCodable = AnyCodable([String]())) throws -> Request {
        try Request(topic: topic, method: method, params: params, chainId: Blockchain(chainId)!)
    }

    static func payload(method: String = "eth_sendTransaction", kind: WCNRequestPayload.Kind = .transaction, from: String? = address) throws -> WCNRequestPayload {
        try WCNRequestPayload(request: request(method: method), kind: kind, from: from)
    }

    static func context(payload: WCNRequestPayload? = nil, verifyContext: VerifyContext? = nil, approvedAccounts: [WalletConnectUtils.Account] = []) throws -> WCNVerificationContext {
        try WCNVerificationContext(payload: payload ?? self.payload(), verifyContext: verifyContext, accountId: "account-1", approvedAccounts: approvedAccounts)
    }
}

final class WCNSpySignClient: IWCNSignClient {
    struct Call: Equatable {
        let topic: String
        let requestId: RPCID
        let response: RPCResult
    }

    private(set) var calls = [Call]()
    private(set) var disconnectedTopics = [String]()
    var error: Error?

    var sessions = [Session]() {
        didSet { sessionsSubject.send(sessions) }
    }

    let sessionsSubject = PassthroughSubject<[Session], Never>()
    let sessionUpdateSubject = PassthroughSubject<(topic: String, namespaces: [String: SessionNamespace]), Never>()
    let sessionProposalSubject = PassthroughSubject<(proposal: Session.Proposal, context: VerifyContext?), Never>()
    let sessionRequestSubject = PassthroughSubject<(request: Request, context: VerifyContext?), Never>()
    let requestExpirationSubject = PassthroughSubject<RPCID, Never>()
    var pendingRequests = [(request: Request, context: VerifyContext?)]()
    private(set) var pairedUris = [WalletConnectURI]()
    var pairError: Error?

    var sessionsPublisher: AnyPublisher<[Session], Never> { sessionsSubject.eraseToAnyPublisher() }
    var sessionUpdatePublisher: AnyPublisher<(topic: String, namespaces: [String: SessionNamespace]), Never> { sessionUpdateSubject.eraseToAnyPublisher() }
    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> { sessionProposalSubject.eraseToAnyPublisher() }
    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> { sessionRequestSubject.eraseToAnyPublisher() }
    var requestExpirationPublisher: AnyPublisher<RPCID, Never> { requestExpirationSubject.eraseToAnyPublisher() }

    func pair(uri: WalletConnectURI) async throws {
        if let pairError {
            throw pairError
        }
        pairedUris.append(uri)
    }

    func disconnect(topic: String) async throws {
        if let error {
            throw error
        }
        disconnectedTopics.append(topic)
        sessions.removeAll { $0.topic == topic }
    }

    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws {
        if let error {
            throw error
        }
        calls.append(Call(topic: topic, requestId: requestId, response: response))
    }
}

extension WCNTestFixtures {
    static func account(_ caip10: String) -> WalletConnectUtils.Account {
        WalletConnectUtils.Account(caip10)!
    }

    static let approvedMainnet = account("eip155:1:\(address)")
    static let approvedOptimism = account("eip155:10:\(address)")
    static let oneInchRouter = "0x1111111254EEB25477B68fb85Ed929f73A960582"
}

final class WCNStubRequestPayload: WCNRequestPayload, IWCNTypedDataRequest {
    var stubTo: String?
    var stubValue: BigUInt?
    var stubData: Data?
    var stubMessage: Data?
    var stubSwapInfo: WCNSwapInfo?
    var stubDomain: WCNTypedDataDomain?
    var stubSignOnly = false

    override var isSignOnly: Bool { stubSignOnly }
    override var to: String? { stubTo }
    override var value: BigUInt? { stubValue }
    override var data: Data? { stubData }
    override var message: Data? { stubMessage }
    override var decodedSwapInfo: WCNSwapInfo? { stubSwapInfo }
    var typedDataDomain: WCNTypedDataDomain? { stubDomain }

    static func make(method: String = "eth_sendTransaction", chainId: String = "eip155:1", kind: WCNRequestPayload.Kind = .transaction, from: String? = WCNTestFixtures.address) throws -> WCNStubRequestPayload {
        try WCNStubRequestPayload(request: WCNTestFixtures.request(method: method, chainId: chainId), kind: kind, from: from)
    }
}

final class WCNStubSwapRouterProvider: IWCNSwapRouterProvider {
    var routers = [String: String]()

    func routerAddress(provider _: WCNSwapInfo.Provider, chainId: Blockchain) -> String? {
        routers[chainId.absoluteString]
    }
}
