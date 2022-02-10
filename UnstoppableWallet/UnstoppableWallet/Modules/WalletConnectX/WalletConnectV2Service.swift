import WalletConnect
import WalletConnectUtils
import CryptoSwift
import RxSwift
import RxRelay

class WalletConnectV2Service {
    private let client: WalletConnectClient

    private let receiveProposalRelay = PublishRelay<Session.Proposal>()
    private let receiveSessionRelay = PublishRelay<Session>()
    private let deleteSessionRelay = PublishRelay<(String, Reason)>()

    private let sessionItemUpdatedRelay = PublishRelay<()>()
    private let requestUpdatedRelay = PublishRelay<Request>()
    private let sessionRequestUpdatedRelay = PublishRelay<Request>()

    init(info: WalletConnectClientInfo) {
        let metadata = AppMetadata(
                name: info.name,
                description: info.description,
                url: info.url,
                icons: info.icons
        )

        client = WalletConnectClient(
                metadata: metadata,
                projectId: info.projectId,
                isController: true,
                relayHost: info.relayHost
        )

        updateSessions()
        client.delegate = self
    }

    private func updateSessions() {
        //renew sessions and send signal to update if needed
        sessionItemUpdatedRelay.accept(())
    }

    private func activeSessionItem(for settledSessions: [Session]) -> [WalletConnectV2SessionItem] {
        let sessionItems = settledSessions
                .map {
                    WalletConnectV2SessionItem(
                            topic: $0.topic,
                            dappName: $0.peer.name,
                            dappURL: $0.peer.url,
                            iconURL: $0.peer.icons?.last
                    )
                }
        return sessionItems.sorted { $0.topic > $1.topic }
    }

}

extension WalletConnectV2Service {

    // helpers
    public func ping(topic: String, completion: @escaping (Result<Void, Error>) -> ()) {
        client.ping(topic: topic, completion: completion)
    }

    // works with session info
    public var activeSessions: [Session] {
        client.getSettledSessions()
    }

    public var sessionItems: [WalletConnectV2SessionItem] {
        activeSessionItem(for: client.getSettledSessions())
    }

    public var sessionsUpdatedObservable: Observable<()> {
        sessionItemUpdatedRelay.asObservable()
    }

    public var requestUpdatedObservable: Observable<Request> {
        requestUpdatedRelay.asObservable()
    }

    public var pendingRequests: [Request] {
        client.getPendingRequests()
    }

    public var receiveProposalObservable: Observable<Session.Proposal> {
        receiveProposalRelay.asObservable()
    }

    public var receiveSessionObservable: Observable<Session> {
        receiveSessionRelay.asObservable()
    }

    public var deleteSessionObservable: Observable<(String, Reason)> {
        deleteSessionRelay.asObservable()
    }

    // works with dApp
    public func pair(uri: String) throws {
        do {
            try client.pair(uri: uri)
        } catch {
            //can't pair with dApp, duplicate pairing or can't parse uri
            throw error
        }
    }

    public func approve(proposal: Session.Proposal, accounts: Set<String>) {
        client.approve(proposal: proposal, accounts: accounts)
    }

    public func reject(proposal: Session.Proposal) {
        client.reject(proposal: proposal, reason: Reason(code: 0, message: "reject"))
    }

    public func respond(topic: String, response: JsonRpcResult) {
        client.respond(topic: topic, response: response)
    }

    public func disconnect(topic: String, reason: Reason) {
        client.disconnect(topic: topic, reason: reason)
        updateSessions()
    }

    //Works with Requests
    public var sessionRequestObservable: Observable<Request> {
        sessionRequestUpdatedRelay.asObservable()
    }

    public func sign(request: Request) {
        let result = AnyCodable("")// Signer.signEth(request: request)
        let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
        client.respond(topic: request.topic, response: .response(response))

        sessionRequestUpdatedRelay.accept(request)
    }

    public func reject(request: Request) {
        client.respond(topic: request.topic, response: .error(JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))

        sessionRequestUpdatedRelay.accept(request)
    }

}

extension WalletConnectV2Service: WalletConnectClientDelegate {

    public func didReceive(sessionProposal: Session.Proposal) {
        receiveProposalRelay.accept(sessionProposal)
    }

    //Receive request from dApp
    public func didReceive(sessionRequest: Request) {
        print("didReceive(sessionRequest:")
        sessionRequestUpdatedRelay.accept(sessionRequest)
    }

    func didReceive(notification: Session.Notification, sessionTopic: String) {
        print("didReceive(notification: \(sessionTopic) : \(notification.type) : \(notification.data)")
    }

    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
        print("didUpgrade(sessionTopic: \(sessionTopic) : \(Array(permissions.blockchains))")
    }

    func didUpdate(sessionTopic: String, accounts: Set<String>) {
        print("didUpdate(sessionTopic: \(sessionTopic) : \(Array(accounts))")
    }

    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {
        print("didUpdate(pairingTopic: String \(pairingTopic) : \(appMetadata.description ?? "NA")")
    }

    // dApp disconnected session
    func didDelete(sessionTopic: String, reason: Reason) {
        print("didDelete(sessionTopic: String \(sessionTopic) : \(reason.message)")

        deleteSessionRelay.accept((sessionTopic, reason))
        updateSessions()
    }

    public func didSettle(session: Session) {
        receiveSessionRelay.accept(session)
        updateSessions()
    }

    public func didSettle(pairing: Pairing) {
        print("didSettle(pairing:")
    }

    public func didReject(pendingSessionTopic: String, reason: Reason) {
        print("didReject(pendingSessionTopic: \(pendingSessionTopic) : reason:\(reason)")
        updateSessions()
    }

}

struct WalletConnectClientInfo {
    let projectId: String
    let relayHost: String
    let clientName: String?
    let name: String?
    let description: String?
    let url: String?
    let icons: [String]
}

struct WalletConnectV2SessionItem: Hashable {
    let topic: String
    let dappName: String?
    let dappURL: String?
    let iconURL: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(topic)
    }

}

extension Session: Hashable {

    public var id: Int {
        hashValue
    }

    public static func ==(lhs: Session, rhs: Session) -> Bool {
        lhs.topic == rhs.topic
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(topic)
    }

}


//
//
//import WalletConnect
//import WalletConnectUtils
//import CryptoSwift
//import RxSwift
//import RxRelay
//
//class WalletConnectV2Service {
//    private let client: WalletConnectClient
//    private let accountFetcher: WalletConnectV2AccountFetcher
//
//    private let sessionItemUpdatedRelay = PublishRelay<()>()
//    private let requestUpdatedRelay = PublishRelay<Request>()
//    private let pairingStateRelay = BehaviorRelay<PairingState>(value: .idle)
//    private let sessionRequestUpdatedRelay = PublishRelay<Request>()
//
//    private(set) var pairingState: PairingState = .idle {
//        didSet {
//            pairingStateRelay.accept(pairingState)
//        }
//    }
//
//    init(info: WalletConnectClientInfo, accountFetcher: WalletConnectV2AccountFetcher) {
//        let metadata = AppMetadata(
//                name: info.name,
//                description: info.description,
//                url: info.url,
//                icons: info.icons
//        )
//
//        client = WalletConnectClient(
//                metadata: metadata,
//                projectId: info.projectId,
//                isController: true,
//                relayHost: info.relayHost
//        )
//
//        self.accountFetcher = accountFetcher
//
//        updateSessions()
//        client.delegate = self
//    }
//
//    private func updateSessions() {
//        //renew sessions and send signal to update if needed
//        sessionItemUpdatedRelay.accept(())
//    }
//
//    private func activeSessionItem(for settledSessions: [Session]) -> [WalletConnectV2SessionItem] {
//        let sessionItems = settledSessions
//                .map {
//                    WalletConnectV2SessionItem(
//                            topic: $0.topic,
//                            dappName: $0.peer.name,
//                            dappURL: $0.peer.url,
//                            iconURL: $0.peer.icons?.last
//                    )
//                }
//        return sessionItems.sorted { $0.topic > $1.topic }
//    }
//
//}
//
//extension WalletConnectV2Service {
//
//    // helpers
//    public func ping(topic: String, completion: @escaping (Result<Void, Error>) -> ()) {
//        client.ping(topic: topic, completion: completion)
//    }
//
//    // works with session info
//    public var activeSessions: [Session] {
//        client.getSettledSessions()
//    }
//
//    public var sessionItems: [WalletConnectV2SessionItem] {
//        activeSessionItem(for: client.getSettledSessions())
//    }
//
//    public var sessionsUpdatedObservable: Observable<()> {
//        sessionItemUpdatedRelay.asObservable()
//    }
//
//    public var requestUpdatedObservable: Observable<Request> {
//        requestUpdatedRelay.asObservable()
//    }
//
//    public var pairingStateObservable: Observable<PairingState> {
//        pairingStateRelay.asObservable()
//    }
//
//    public var pendingRequests: [Request] {
//        client.getPendingRequests()
//    }
//
//    // works with dApp
//    public func pair(uri: String) throws {
//        do {
//            try client.pair(uri: uri)
//            pairingState = .pairing
//        } catch {
//            //can't pair with dApp, duplicate pairing or can't parse uri
//            pairingState = .pairingError(error)
//            throw error
//        }
//    }
//
//    public func approve(proposal: Session.Proposal) {
//        pairingState = .connected
//
//        let accounts = proposal.permissions.blockchains.compactMap { accountFetcher.account(blockchain: $0) }
//        client.approve(proposal: proposal, accounts: Set(accounts))
//    }
//
//    public func reject(proposal: Session.Proposal) {
//        client.reject(proposal: proposal, reason: Reason(code: 0, message: "reject"))
//    }
//
//    public func respond(topic: String, response: JsonRpcResult) {
//        client.respond(topic: topic, response: response)
//    }
//
//    public func disconnect(item: WalletConnectV2SessionItem, reason: Reason) {
//        print("disconnect!")
//        client.disconnect(topic: item.topic, reason: reason)
//        updateSessions()
//    }
//
//    //Works with Requests
//    public var sessionRequestObservable: Observable<Request> {
//        sessionRequestUpdatedRelay.asObservable()
//    }
//
//    public func sign(request: Request) {
//        let result = AnyCodable("")// Signer.signEth(request: request)
//        let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
//        client.respond(topic: request.topic, response: .response(response))
//
//        sessionRequestUpdatedRelay.accept(request)
//    }
//
//    public func reject(request: Request) {
//        client.respond(topic: request.topic, response: .error(JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
//
//        sessionRequestUpdatedRelay.accept(request)
//    }
//
//}
//
//extension WalletConnectV2Service {
//
//    enum PairingState {
//        case idle
//        case pairing
//        case pairingSettled
//        case proposalReceived(Session.Proposal)
//        case connected
//        case pairingError(Error)
//    }
//
//}
//
//extension WalletConnectV2Service: WalletConnectClientDelegate {
//
//    public func didReceive(sessionProposal: Session.Proposal) {
//        print("didReceive(sessionProposal:")
//        pairingState = .proposalReceived(sessionProposal)
//    }
//
//    //Receive request from dApp
//    public func didReceive(sessionRequest: Request) {
//        print("didReceive(sessionRequest:")
//        sessionRequestUpdatedRelay.accept(sessionRequest)
//    }
//
//    func didReceive(notification: Session.Notification, sessionTopic: String) {
//        print("didReceive(notification: \(sessionTopic) : \(notification.type) : \(notification.data)")
//    }
//
//    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
//        print("didUpgrade(sessionTopic: \(sessionTopic) : \(Array(permissions.blockchains))")
//    }
//
//    func didUpdate(sessionTopic: String, accounts: Set<String>) {
//        print("didUpdate(sessionTopic: \(sessionTopic) : \(Array(accounts))")
//    }
//
//    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {
//        print("didUpdate(pairingTopic: String \(pairingTopic) : \(appMetadata.description ?? "NA")")
//    }
//
//    // dApp disconnected session
//    func didDelete(sessionTopic: String, reason: Reason) {
//        print("didDelete(sessionTopic: String \(sessionTopic) : \(reason.message)")
//        updateSessions()
//    }
//
//    public func didSettle(session: Session) {
//        print("didSettle(session:")
//        updateSessions()
//    }
//
//    public func didSettle(pairing: Pairing) {
//        print("didSettle(pairing:")
//        pairingState = .pairingSettled
//    }
//
//    public func didReject(pendingSessionTopic: String, reason: Reason) {
//        print("didReject(pendingSessionTopic: \(pendingSessionTopic) : reason:\(reason)")
//        updateSessions()
//    }
//
//}
//
//struct WalletConnectClientInfo {
//    let projectId: String
//    let relayHost: String
//    let clientName: String?
//    let name: String?
//    let description: String?
//    let url: String?
//    let icons: [String]
//}
//
//struct WalletConnectV2SessionItem: Hashable {
//    let topic: String
//    let dappName: String?
//    let dappURL: String?
//    let iconURL: String?
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(topic)
//    }
//
//}
//
//extension Session: Hashable {
//
//    public var id: Int {
//        hashValue
//    }
//
//    public static func ==(lhs: Session, rhs: Session) -> Bool {
//        lhs.topic == rhs.topic
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(topic)
//    }
//
//}
