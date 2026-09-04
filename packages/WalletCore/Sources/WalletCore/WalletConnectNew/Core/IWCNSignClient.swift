import Combine
import ReownWalletKit

protocol IWCNSignClient: AnyObject {
    var sessions: [Session] { get }
    var sessionsPublisher: AnyPublisher<[Session], Never> { get }
    var sessionUpdatePublisher: AnyPublisher<(topic: String, namespaces: [String: SessionNamespace]), Never> { get }
    func disconnect(topic: String) async throws
    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws
}
