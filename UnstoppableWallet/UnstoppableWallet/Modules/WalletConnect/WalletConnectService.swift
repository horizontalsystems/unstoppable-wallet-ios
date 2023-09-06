import Foundation
import CryptoSwift
import RxSwift
import RxRelay
import Combine
import Starscream
import WalletConnectKMS
import WalletConnectSign
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectNetworking
import WalletConnectPairing
import HsToolKit

extension Starscream.WebSocket: WebSocketConnecting { }

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        Starscream.WebSocket(url: url)
    }
}

class WalletConnectService {
    private let logger: Logger?
    private let connectionService: WalletConnectSocketConnectionService
    private let sessionRequestFilterManager: SessionRequestFilterManager

    private let receiveProposalSubject = PublishSubject<WalletConnectSign.Session.Proposal>()
    private let receiveSessionRelay = PublishRelay<WalletConnectSign.Session>()
    private let deleteSessionRelay = PublishRelay<(String, WalletConnectSign.Reason)>()

    private let sessionsItemUpdatedRelay = PublishRelay<()>()
    private let pendingRequestsUpdatedRelay = PublishRelay<()>()
    private let pairingUpdatedRelay = PublishRelay<()>()
    private let sessionRequestReceivedRelay = PublishRelay<WalletConnectSign.Request>()

    private let socketConnectionStatusRelay = PublishRelay<WalletConnectMainModule.ConnectionState>()
    private(set) var socketConnectionStatus: WalletConnectMainModule.ConnectionState = .disconnected {
        didSet {
            socketConnectionStatusRelay.accept(socketConnectionStatus)
        }
    }

    private var publishers = [AnyCancellable]()

    init(connectionService: WalletConnectSocketConnectionService, sessionRequestFilterManager: SessionRequestFilterManager, info: WalletConnectClientInfo, logger: Logger? = nil) {
        self.connectionService = connectionService
        self.sessionRequestFilterManager = sessionRequestFilterManager
        self.logger = logger
        let metadata = WalletConnectSign.AppMetadata(
                name: info.name,
                description: info.description,
                url: info.url,
                icons: info.icons
        )

        Networking.configure(projectId: info.projectId, socketFactory: SocketFactory(), socketConnectionType: .manual)
        Pair.configure(metadata: metadata)
        setUpAuthSubscribing()

        connectionService.relayClient = Relay.instance

        updateSessions()
        updatePairings()
    }

    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.didChangeSocketConnectionStatus(status)
                }.store(in: &publishers)

        Sign.instance.sessionProposalPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sessionProposal in
                    self?.didReceive(sessionProposal: sessionProposal.proposal)
                }.store(in: &publishers)

        Sign.instance.sessionSettlePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] session in
                    self?.didSettle(session: session)
                }.store(in: &publishers)

        Sign.instance.sessionUpdatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] pair in
                    self?.didUpdate(sessionTopic: pair.sessionTopic, namespaces: pair.namespaces)
                }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sessionRequest in
                    self?.didReceive(sessionRequest: sessionRequest.request)
                }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] tuple in
                    self?.didDelete(sessionTopic: tuple.0, reason: tuple.1)
                }.store(in: &publishers)
    }


    private func updateSessions() {
        sessionsItemUpdatedRelay.accept(())
    }

    private func updatePairings() {
        pairingUpdatedRelay.accept(())
    }

}

extension WalletConnectService {

    public func didReceive(sessionProposal: Session.Proposal) {
        logger?.debug("WC v2 SignClient did receive session proposal: \(sessionProposal.id) : proposer: \(sessionProposal.proposer.name)")
        receiveProposalSubject.onNext(sessionProposal)
    }

    public func didReceive(sessionRequest: Request) {
        logger?.debug("WC v2 SignClient did receive session request: \(sessionRequest.method) : session: \(sessionRequest.topic)")

        if sessionRequestFilterManager.handle(request: sessionRequest) {
            return
        }

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
        socketConnectionStatus = status.connectionState
    }

}

extension WalletConnectService {

    // helpers
    public func ping(topic: String, completion: @escaping (Result<Void, Error>) -> ()) {
        Task(priority: .userInitiated) { @MainActor in
            do {
                try await Sign.instance.ping(topic: topic)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // works with sessions
    public var activeSessions: [WalletConnectSign.Session] {
        Sign.instance.getSessions()
    }

    public var sessionsUpdatedObservable: Observable<()> {
        sessionsItemUpdatedRelay.asObservable()
    }

    // works with pending requests
    public var pendingRequests: [WalletConnectSign.Request] {
        Sign.instance.getPendingRequests()
    }

    public var pendingRequestsUpdatedObservable: Observable<()> {
        pendingRequestsUpdatedRelay.asObservable()
    }

    // works with pairings
    public var pairings: [WalletConnectPairing.Pairing] {
        Pair.instance.getPairings()
    }

    public var pairingUpdatedObservable: Observable<()> {
        pairingUpdatedRelay.asObservable()
    }

    public func disconnectPairing(topic: String) -> Single<()> {
        Single.create { observer in
            Task { [weak self] in
                do {
                    try await Pair.instance.disconnect(topic: topic)
                    self?.updatePairings()
                    observer(.success(()))
                } catch {
                    self?.updatePairings()
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    // connect/disconnect session
    public var receiveProposalObservable: Observable<WalletConnectSign.Session.Proposal> {
        receiveProposalSubject.asObservable()
    }

    public var receiveSessionObservable: Observable<WalletConnectSign.Session> {
        receiveSessionRelay.asObservable()
    }

    public var deleteSessionObservable: Observable<(String, WalletConnectSign.Reason)> {
        deleteSessionRelay.asObservable()
    }

    public var socketConnectionStatusObservable: Observable<WalletConnectMainModule.ConnectionState> {
        socketConnectionStatusRelay.asObservable()
    }

    // works with dApp
    public func validate(uri: String) throws -> WalletConnectUtils.WalletConnectURI {
        guard let uri = WalletConnectUtils.WalletConnectURI(string: uri) else {
            throw WalletConnectUriHandler.ConnectionError.wrongUri
        }
        return uri
    }

    public func pair(uri: WalletConnectUtils.WalletConnectURI) async throws {
        Task.init { [weak self] in
            do {
                try await Pair.instance.pair(uri: uri)
                self?.updatePairings()
            } catch {
                //can't pair with dApp, duplicate pairing or can't parse uri
                throw error
            }
        }
    }

    public func approve(proposal: WalletConnectSign.Session.Proposal, accounts: Set<WalletConnectUtils.Account>, methods: Set<String>, events: Set<String>) async throws {
        logger?.debug("[WALLET] Approve Session: \(proposal.id)")
        Task { [logger] in
            do {
                let eip155 = WalletConnectSign.SessionNamespace(
                        accounts: accounts,
                        methods: methods,
                        events: events
                )
                try await Sign.instance.approve(proposalId: proposal.id, namespaces: ["eip155": eip155])
            } catch {
                logger?.error("WC v2 can't approve proposal, cause: \(error.localizedDescription)")
                throw error
            }
        }
    }

    public func reject(proposal: WalletConnectSign.Session.Proposal) async throws {
        logger?.debug("[WALLET] Reject Session: \(proposal.id)")
        do {
            try await Sign.instance.reject(proposalId: proposal.id, reason: .userRejected)
        } catch {
            logger?.error("WC v2 can't reject proposal, cause: \(error.localizedDescription)")
            throw error
        }
    }

    public func disconnect(topic: String, reason: WalletConnectSign.Reason) {
        Task { [weak self, logger] in
            do {
                try await Sign.instance.disconnect(topic: topic)
                self?.updateSessions()
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
        let result = AnyCodable(result.hs.hexString)// Signer.signEth(request: request)
        Task { [weak self] in
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(result))
                self?.pendingRequestsUpdatedRelay.accept(())
            }
        }
    }

    public func reject(request: WalletConnectSign.Request) {
        Task { [weak self] in
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 5000, message: "Reject by User")))
                self?.pendingRequestsUpdatedRelay.accept(())
            }
        }
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

extension WalletConnectService: IWalletConnectSignService {

    func approveRequest(id: Int, result: Data) {
        guard let request = pendingRequests.first(where: { $0.id.intValue == id }) else {
            return
        }
        sign(request: request, result: result)
    }

    func rejectRequest(id: Int) {
        guard let request = pendingRequests.first(where: { $0.id.intValue == id }) else {
            return
        }
        reject(request: request)
    }

}

extension RPCID {

    var intValue: Int {
        (left?.hashValue ?? 0) + Int(right ?? 0) //todo: id potentially can be wrong
    }

    var int64Value: Int64 {
        Int64(intValue)
    }

}

extension WalletConnectSign.SocketConnectionStatus {
    var connectionState: WalletConnectMainModule.ConnectionState {
        switch self {
        case .connected: return .connected
        case .disconnected: return .disconnected
        }
    }
}
