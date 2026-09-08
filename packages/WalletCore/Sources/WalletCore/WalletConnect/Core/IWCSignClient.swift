import Combine
import ReownWalletKit

protocol IWCSignClient: AnyObject {
    var sessions: [Session] { get }
    var sessionsPublisher: AnyPublisher<[Session], Never> { get }
    var sessionUpdatePublisher: AnyPublisher<(topic: String, namespaces: [String: SessionNamespace]), Never> { get }
    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> { get }
    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> { get }
    var requestExpirationPublisher: AnyPublisher<RPCID, Never> { get }
    var pendingRequests: [(request: Request, context: VerifyContext?)] { get }
    func pair(uri: WalletConnectURI) async throws
    func approve(proposalId: String, namespaces: [String: SessionNamespace]) async throws -> Session
    func rejectSession(proposalId: String) async throws
    func disconnect(topic: String) async throws
    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws
}
