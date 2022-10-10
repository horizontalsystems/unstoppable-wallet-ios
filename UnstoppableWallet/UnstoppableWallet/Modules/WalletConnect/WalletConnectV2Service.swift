import Foundation
import CryptoSwift
import RxSwift
import RxRelay
import Combine
import WalletConnectSign
import WalletConnectRelay
import WalletConnectUtils
import HsToolKit

class WalletConnectV2Service {
    private let logger: Logger?
    private let connectionService: WalletConnectV2SocketConnectionService

    private let receiveProposalRelay = PublishRelay<WalletConnectSign.Session.Proposal>()
    private let receiveSessionRelay = PublishRelay<WalletConnectSign.Session>()
    private let deleteSessionRelay = PublishRelay<(String, WalletConnectSign.Reason)>()

    private let sessionsItemUpdatedRelay = PublishRelay<()>()
    private let pendingRequestsUpdatedRelay = PublishRelay<()>()
    private let sessionRequestReceivedRelay = PublishRelay<WalletConnectSign.Request>()
    private let socketConnectionStatusRelay = PublishRelay<WalletConnectSign.SocketConnectionStatus>()

    private let signClient: SignClient

    init(connectionService: WalletConnectV2SocketConnectionService, info: WalletConnectClientInfo, logger: Logger? = nil) {
        self.connectionService = connectionService
        self.logger = logger
        let metadata = WalletConnectSign.AppMetadata(
                name: info.name,
                description: info.description,
                url: info.url,
                icons: info.icons
        )
        let relayClient = RelayClient(relayHost: info.relayHost, projectId: info.projectId, socketConnectionType: .manual)
        signClient = SignClient(metadata: metadata, relayClient: relayClient)
        signClient.delegate = self

        connectionService.relayClient = relayClient

        updateSessions()
    }

    private func updateSessions() {
        sessionsItemUpdatedRelay.accept(())
    }

}

extension WalletConnectV2Service: SignClientDelegate {

    public func didReceive(sessionProposal: Session.Proposal) {
        logger?.debug("WC v2 SignClient did receive session proposal: \(sessionProposal.id) : proposer: \(sessionProposal.proposer.name)")
        receiveProposalRelay.accept(sessionProposal)
    }

    public func didReceive(sessionRequest: Request) {
        logger?.debug("WC v2 SignClient did receive session request: \(sessionRequest.method) : session: \(sessionRequest.topic)")
        sessionRequestReceivedRelay.accept(sessionRequest)
        pendingRequestsUpdatedRelay.accept(())
    }

    public func didReceive(sessionResponse: Response) {
        logger?.debug("WC v2 SignClient did receive session response: \(sessionResponse.topic) : chainId: \(sessionResponse.chainId ?? "")")
    }

    public func didReceive(event: Session.Event, sessionTopic: String, chainId: WalletConnectSign.Blockchain?) {
        logger?.debug("WC v2 SignClient did receive session event: \(event.name) : session: \(sessionTopic)")
    }

    public func didDelete(sessionTopic: String, reason: Reason) {
        logger?.debug("WC v2 SignClient did delete session: \(sessionTopic)")
        deleteSessionRelay.accept((sessionTopic, reason))
        updateSessions()
    }

    public func didUpdate(sessionTopic: String, namespaces: [String: SessionNamespace]) {
        logger?.debug("WC v2 SignClient did update session: \(sessionTopic)")
    }

    public func didSettle(session: Session) {
        logger?.debug("WC v2 SignClient did settle session: \(session.topic)")
        receiveSessionRelay.accept(session)
        updateSessions()
    }

    public func didChangeSocketConnectionStatus(_ status: WalletConnectSign.SocketConnectionStatus) {
        logger?.debug("WC v2 SignClient change socketStatus: \(status)")
        socketConnectionStatusRelay.accept(status)
    }

}

extension WalletConnectV2Service {

    // helpers
    public func ping(topic: String, completion: @escaping (Result<Void, Error>) -> ()) {
        signClient.ping(topic: topic, completion: completion)
    }

    // works with sessions
    public var activeSessions: [WalletConnectSign.Session] {
        signClient.getSessions()
    }

    public var sessionsUpdatedObservable: Observable<()> {
        sessionsItemUpdatedRelay.asObservable()
    }

    // works with pending requests
    public var pendingRequests: [WalletConnectSign.Request] {
        signClient.getPendingRequests()
    }

    public var pendingRequestsUpdatedObservable: Observable<()> {
        pendingRequestsUpdatedRelay.asObservable()
    }

    // connect/disconnect session
    public var receiveProposalObservable: Observable<WalletConnectSign.Session.Proposal> {
        receiveProposalRelay.asObservable()
    }

    public var receiveSessionObservable: Observable<WalletConnectSign.Session> {
        receiveSessionRelay.asObservable()
    }

    public var deleteSessionObservable: Observable<(String, WalletConnectSign.Reason)> {
        deleteSessionRelay.asObservable()
    }

    public var socketConnectionStatusObservable: Observable<WalletConnectSign.SocketConnectionStatus> {
        socketConnectionStatusRelay.asObservable()
    }

    // works with dApp
    public func pair(uri: String) throws {
        Task.init {
            do {
                try await signClient.pair(uri: uri) //fix async behaviour
            } catch {
                //can't pair with dApp, duplicate pairing or can't parse uri
                throw error
            }
        }
    }

    public func approve(proposal: WalletConnectSign.Session.Proposal, accounts: Set<WalletConnectUtils.Account>, methods: Set<String>, events: Set<String>) throws {
        do {
            let eip155 = WalletConnectSign.SessionNamespace(
                    accounts: accounts,
                    methods: methods,
                    events: events,
                    extensions: []
            )
            try signClient.approve(proposalId: proposal.id, namespaces: ["eip155": eip155])
        } catch {
            logger?.error("WC v2 can't approve proposal, cause: \(error.localizedDescription)")
            throw error
        }
    }

    public func reject(proposal: WalletConnectSign.Session.Proposal) throws {
        do {
            try signClient.reject(proposalId: proposal.id, reason: .disapprovedChains)
        } catch {
            logger?.error("WC v2 can't reject proposal, cause: \(error.localizedDescription)")
            throw error
        }
    }

    public func respond(topic: String, response: JsonRpcResult) {
        signClient.respond(topic: topic, response: response)
    }

    public func disconnect(topic: String, reason: WalletConnectSign.Reason) {
        Task.init {
            do {
                try await signClient.disconnect(topic: topic, reason: reason) //todo: handle async behaviour
                updateSessions()
            } catch {
                logger?.error("WC v2 can't disconnect topic, cause: \(error.localizedDescription)")
            }
        }
    }

    //Works with Requests
    public var sessionRequestReceivedObservable: Observable<WalletConnectSign.Request> {
        sessionRequestReceivedRelay.asObservable()
    }

    public func sign(request: WalletConnectSign.Request, result: Data) {
        let result = AnyCodable(result)// Signer.signEth(request: request)
        let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
        signClient.respond(topic: request.topic, response: .response(response))

        pendingRequestsUpdatedRelay.accept(())
    }

    public func reject(request: WalletConnectSign.Request) {
        signClient.respond(topic: request.topic, response: .error(JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: "reject by User"))))

        pendingRequestsUpdatedRelay.accept(())
    }

}

struct WalletConnectClientInfo {
    let projectId: String
    let relayHost: String
    let name: String
    let description: String
    let url: String
    let icons: [String]
}

extension WalletConnectSign.Session: Hashable {

    public var id: Int {
        hashValue
    }

    public static func ==(lhs: WalletConnectSign.Session, rhs: WalletConnectSign.Session) -> Bool {
        lhs.topic == rhs.topic
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(topic)
    }

}

extension WalletConnectV2Service: IWalletConnectSignService {

    func approveRequest(id: Int, result: Data) {
        guard let request = pendingRequests.first(where: { $0.id == id }) else {
            return
        }
        sign(request: request, result: result)
    }

    func rejectRequest(id: Int) {
        guard let request = pendingRequests.first(where: { $0.id == id }) else {
            return
        }
        reject(request: request)
    }

}
