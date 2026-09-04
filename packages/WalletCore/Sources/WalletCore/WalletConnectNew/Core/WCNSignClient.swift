import Combine
import ReownWalletKit

// The only place that touches WalletKit.instance
class WCNSignClient: IWCNSignClient {
    var sessions: [Session] {
        WalletKit.instance.getSessions()
    }

    var sessionsPublisher: AnyPublisher<[Session], Never> {
        WalletKit.instance.sessionsPublisher
    }

    var sessionUpdatePublisher: AnyPublisher<(topic: String, namespaces: [String: SessionNamespace]), Never> {
        Sign.instance.sessionUpdatePublisher
            .map { (topic: $0.sessionTopic, namespaces: $0.namespaces) }
            .eraseToAnyPublisher()
    }

    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> {
        WalletKit.instance.sessionProposalPublisher
    }

    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        WalletKit.instance.sessionRequestPublisher
    }

    var requestExpirationPublisher: AnyPublisher<RPCID, Never> {
        WalletKit.instance.requestExpirationPublisher
    }

    var pendingRequests: [(request: Request, context: VerifyContext?)] {
        WalletKit.instance.getPendingRequests()
    }

    func pair(uri: WalletConnectURI) async throws {
        WCNLog.log("sdk pair: \(uri.topic.prefix(8))")
        try await WalletKit.instance.pair(uri: uri)
        WCNLog.log("sdk pair: returned")
    }

    func approve(proposalId: String, namespaces: [String: SessionNamespace]) async throws -> Session {
        WCNLog.log("sdk approve: \(proposalId) namespaces=\(namespaces.mapValues { $0.accounts.map(\.absoluteString) })")
        return try await WalletKit.instance.approve(proposalId: proposalId, namespaces: namespaces)
    }

    func rejectSession(proposalId: String) async throws {
        WCNLog.log("sdk rejectSession: \(proposalId)")
        try await WalletKit.instance.rejectSession(proposalId: proposalId, reason: .userRejected)
    }

    func disconnect(topic: String) async throws {
        WCNLog.log("sdk disconnect: \(topic.prefix(8))")
        try await WalletKit.instance.disconnect(topic: topic)
    }

    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws {
        WCNLog.log("sdk respond: id=\(requestId.string) topic=\(topic.prefix(8)) response=\(response)")
        try await WalletKit.instance.respond(topic: topic, requestId: requestId, response: response)
    }
}
