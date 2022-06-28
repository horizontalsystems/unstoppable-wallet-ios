import CryptoSwift
import RxSwift
import RxRelay
import Combine
import WalletConnectSign
import WalletConnectUtils
import HsToolKit

class WalletConnectV2Service {
    private let logger: Logger?
    let connectionService: WalletConnectV2SocketConnectionService

    private let receiveProposalRelay = PublishRelay<WalletConnectSign.Session.Proposal>()
    private let receiveSessionRelay = PublishRelay<WalletConnectSign.Session>()
    private let deleteSessionRelay = PublishRelay<(String, WalletConnectSign.Reason)>()

    private let sessionsItemUpdatedRelay = PublishRelay<()>()
    private let pendingRequestsUpdatedRelay = PublishRelay<()>()
    private let sessionRequestReceivedRelay = PublishRelay<WalletConnectSign.Request>()

    private var cancellables = Set<AnyCancellable>()

    init(connectionService: WalletConnectV2SocketConnectionService, info: WalletConnectClientInfo, logger: Logger? = nil) {
        self.connectionService = connectionService
        let metadata = WalletConnectSign.AppMetadata(
                name: info.name,
                description: info.description,
                url: info.url,
                icons: info.icons
        )
        self.logger = logger
        Sign.configure(Sign.Config(metadata: metadata, projectId: info.projectId, socketConnectionType: .manual))

        connectionService.start()
        updateSessions()
        subscribeSign()
    }

    private func updateSessions() {
        sessionsItemUpdatedRelay.accept(())
    }

    private func subscribeSign() {
        Sign.instance
                .sessionProposalPublisher
                .sink { [weak self] in
                    self?.receiveProposalRelay.accept($0)
                }
                .store(in: &cancellables)
        Sign.instance
                .sessionRequestPublisher
                .sink { [weak self] in
                    self?.sessionRequestReceivedRelay.accept($0)
                    self?.pendingRequestsUpdatedRelay.accept(())
                }
                .store(in: &cancellables)
        Sign.instance
                .sessionDeletePublisher
                .sink { [weak self] in
                    self?.deleteSessionRelay.accept(($0, $1))
                    self?.updateSessions()
                }
                .store(in: &cancellables)
        Sign.instance
                .sessionSettlePublisher
                .sink { [weak self] in
                    self?.receiveSessionRelay.accept($0)
                    self?.updateSessions()
                }
                .store(in: &cancellables)
    }

}

extension WalletConnectV2Service {

    // helpers
    public func ping(topic: String, completion: @escaping (Result<Void, Error>) -> ()) {
        Sign.instance.ping(topic: topic, completion: completion)
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

    // works with dApp
    public func pair(uri: String) throws {
        Task.init {
            do {
                try await Sign.instance.pair(uri: uri) //fix async behaviour
            } catch {
                //can't pair with dApp, duplicate pairing or can't parse uri
                throw error
            }
        }
    }

    public func approve(proposal: WalletConnectSign.Session.Proposal, accounts: Set<WalletConnectUtils.Account>, methods: Set<String>, events: Set<String>) {
        do {
            let eip155 = WalletConnectSign.SessionNamespace(
                    accounts: accounts,
                    methods: methods,
                    events: events,
                    extensions: []
            )
            try Sign.instance.approve(proposalId: proposal.id, namespaces: ["eip155": eip155]) //todo: catch error state
        } catch {
            print(error)
        }
    }

    public func reject(proposal: WalletConnectSign.Session.Proposal) {
        do {
            try Sign.instance.reject(proposalId: proposal.id, reason: .disapprovedChains) //todo: catch error state
        } catch {
            print(error)
        }
    }

    public func respond(topic: String, response: JsonRpcResult) {
        Sign.instance.respond(topic: topic, response: response)
    }

    public func disconnect(topic: String, reason: WalletConnectSign.Reason) {
        Task.init {
            do {
                try await Sign.instance.disconnect(topic: topic, reason: reason) //todo: handle async behaviour
                updateSessions()
            } catch {
                print(error)
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
        Sign.instance.respond(topic: request.topic, response: .response(response))

        pendingRequestsUpdatedRelay.accept(())
    }

    public func reject(request: WalletConnectSign.Request) {
        Sign.instance.respond(topic: request.topic, response: .error(JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: "reject by User"))))

        pendingRequestsUpdatedRelay.accept(())
    }

}

struct WalletConnectClientInfo {
    let projectId: String
    let relayHost: String
    let clientName: String
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
