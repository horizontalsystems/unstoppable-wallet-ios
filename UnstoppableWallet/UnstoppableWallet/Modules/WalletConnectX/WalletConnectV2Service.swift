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

    private let sessionsItemUpdatedRelay = PublishRelay<()>()
    private let pendingRequestsUpdatedRelay = PublishRelay<()>()
    private let sessionRequestReceivedRelay = PublishRelay<Request>()

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
        sessionsItemUpdatedRelay.accept(())
    }

}

extension WalletConnectV2Service {

    // helpers
    public func ping(topic: String, completion: @escaping (Result<Void, Error>) -> ()) {
        client.ping(topic: topic, completion: completion)
    }

    // works with sessions
    public var activeSessions: [Session] {
        client.getSettledSessions()
    }

    public var sessionsUpdatedObservable: Observable<()> {
        sessionsItemUpdatedRelay.asObservable()
    }

    // works with pending requests
    public var pendingRequests: [Request] {
        client.getPendingRequests()
    }

    public var pendingRequestsUpdatedObservable: Observable<()> {
        pendingRequestsUpdatedRelay.asObservable()
    }

    // connect/disconnect session
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
    public var sessionRequestReceivedObservable: Observable<Request> {
        sessionRequestReceivedRelay.asObservable()
    }

    public func sign(request: Request, result: Data) {
        let result = AnyCodable(result)// Signer.signEth(request: request)
        let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
        client.respond(topic: request.topic, response: .response(response))

        pendingRequestsUpdatedRelay.accept(())
    }

    public func reject(request: Request) {
        client.respond(topic: request.topic, response: .error(JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: "reject by User"))))

        pendingRequestsUpdatedRelay.accept(())
    }

}

extension WalletConnectV2Service: WalletConnectClientDelegate {

    public func didReceive(sessionProposal: Session.Proposal) {
        receiveProposalRelay.accept(sessionProposal)
    }

    //Receive request from dApp
    public func didReceive(sessionRequest: Request) {
        sessionRequestReceivedRelay.accept(sessionRequest)
        pendingRequestsUpdatedRelay.accept(())
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
