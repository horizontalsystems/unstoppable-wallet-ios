import RxSwift
import RxRelay
import RxCocoa
import WalletConnectUtils
import WalletConnectSign
import MarketKit

class WalletConnectListService {
    private var disposeBag = DisposeBag()

    private let createModuleRelay = PublishRelay<IWalletConnectMainService>()
    private let connectionErrorRelay = PublishRelay<Error>()

    private let sessionManager: WalletConnectSessionManager
    private let sessionManagerV2: WalletConnectV2SessionManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmChainParser: WalletConnectEvmChainParser

    private var sessionKiller: WalletConnectSessionKiller?
    private let showSessionV1Relay = PublishRelay<WalletConnectSession>()
    private let showSessionV2Relay = PublishRelay<WalletConnectSign.Session>()
    private let sessionKillingRelay = PublishRelay<SessionKillingState>()


    init(sessionManager: WalletConnectSessionManager, sessionManagerV2: WalletConnectV2SessionManager, evmBlockchainManager: EvmBlockchainManager, evmChainParser: WalletConnectEvmChainParser) {
        self.sessionManager = sessionManager
        self.sessionManagerV2 = sessionManagerV2
        self.evmBlockchainManager = evmBlockchainManager
        self.evmChainParser = evmChainParser
    }

    private func onUpdateSessionKiller(state: WalletConnectSessionKiller.State) {
        switch state {
        case .killed: finishSessionKill()
        case .failed: finishSessionKill(successful: false)
        default: ()
        }
    }

    private func finishSessionKill(successful: Bool = true) {
        if let killer = sessionKiller {
            sessionManager.deleteSession(peerId: killer.peerId)
        }

        sessionKiller = nil             //deinit session killer and clean disposeBag
        disposeBag = DisposeBag()

        sessionKillingRelay.accept(successful ? .completed : .removedOnly)
    }

    private func items(sessions: [WalletConnectSession]) -> [Item] {
        sessions.compactMap {
            guard let blockchain = evmBlockchainManager.blockchain(chainId: $0.chainId) else {
                return nil
            }
            return Item(
                    id: $0.id,
                    blockchains: [blockchain],
                    version: 1,
                    appName: $0.peerMeta.name,
                    appUrl: $0.peerMeta.url,
                    appDescription: $0.peerMeta.description,
                    appIcons: $0.peerMeta.icons
            )
        }
    }

    private func items(sessions: [WalletConnectSign.Session]) -> [Item] {
        sessions.map { session in
            let blockchains = session.chainIds.compactMap {
                evmBlockchainManager.blockchain(chainId: $0)
            }
            return Item(
                    id: session.id,
                    blockchains: blockchains,
                    version: 2,
                    appName: session.peer.name,
                    appUrl: session.peer.url,
                    appDescription: session.peer.description,
                    appIcons: session.peer.icons
            )
        }
    }

}

extension WalletConnectListService {

    var emptySessionList: Bool {
        (sessionManager.sessions.count + sessionManagerV2.sessions.count) == 0
    }

    var itemsV1: [Item] {
        items(sessions: sessionManager.sessions)
    }

    var itemsV2: [Item] {
        items(sessions: sessionManagerV2.sessions)
    }

    var itemsV1Observable: Observable<[Item]> {
        sessionManager.sessionsObservable.map { [weak self] in
            self?.items(sessions: $0) ?? []
        }
    }

    var itemsV2Observable: Observable<[Item]> {
        sessionManagerV2.sessionsObservable.map { [weak self] in
            self?.items(sessions: $0) ?? []
        }
    }

    var pendingRequestsV2: [WalletConnectSign.Request] {
        sessionManagerV2.pendingRequests()
    }

    var pendingRequestsV2Observable: Observable<[WalletConnectSign.Request]> {
        sessionManagerV2.pendingRequestsObservable
    }

    var showSessionV1Observable: Observable<WalletConnectSession> {
        showSessionV1Relay.asObservable()
    }

    var showSessionV2Observable: Observable<WalletConnectSign.Session> {
        showSessionV2Relay.asObservable()
    }

    var sessionKillingObservable: Observable<SessionKillingState> {
        sessionKillingRelay.asObservable()
    }

    func kill(id: Int) {
        if let session = sessionManager.sessions.first(where: { $0.id == id }) {
            sessionKillingRelay.accept(.processing)

            let sessionKiller = WalletConnectSessionKiller(session: session)
            let forceTimer = Observable.just(()).delay(.seconds(5), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

            subscribe(disposeBag, forceTimer) { [weak self] in
                self?.finishSessionKill(successful: false)
            }
            subscribe(disposeBag, sessionKiller.stateObservable) { [weak self] in
                self?.onUpdateSessionKiller(state: $0)
            }

            sessionKiller.kill()
            self.sessionKiller = sessionKiller
        }
        if let session = sessionManagerV2.sessions.first(where: { $0.id == id }) {
            sessionKillingRelay.accept(.processing)
            let killTimer = Observable.just(()).delay(.milliseconds(600), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            subscribe(disposeBag, killTimer) { [weak self] in
                self?.sessionManagerV2.deleteSession(topic: session.topic)
                self?.sessionKillingRelay.accept(.completed)
            }
        }
    }

    var createModuleObservable: Observable<IWalletConnectMainService> {
        createModuleRelay.asObservable()
    }

    var connectionErrorObservable: Observable<Error> {
        connectionErrorRelay.asObservable()
    }

    func connect(uri: String) {
        let result = WalletConnectUriHandler.connect(uri: uri)

        switch result {
        case .success(let service): createModuleRelay.accept(service)
        case .failure(let error): connectionErrorRelay.accept(error)
        }
    }

    func showSession(id: Int) {
        if let sessionV1 = sessionManager.sessions.first(where: { $0.id == id }) {
            showSessionV1Relay.accept(sessionV1)
        }
        if let sessionV2 = sessionManagerV2.sessions.first(where: { $0.id == id }) {
            showSessionV2Relay.accept(sessionV2)
        }
    }

}

extension WalletConnectListService {

    enum SessionKillingState {
        case processing
        case completed
        case removedOnly
    }

    struct Item {
        let id: Int
        let blockchains: [MarketKit.Blockchain]
        let version: Int

        let appName: String
        let appUrl: String
        let appDescription: String
        let appIcons: [String]
    }

}

extension WalletConnectSession: Hashable {

    public var id: Int {
        hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accountId)
        hasher.combine(peerId)
    }

    public static func ==(lhs: WalletConnectSession, rhs: WalletConnectSession) -> Bool {
        lhs.accountId == rhs.accountId && lhs.peerId == rhs.peerId
    }

}

extension WalletConnectSign.Session {

    var chainIds: [Int] {
        var result = Set<Int>()

        for blockchain in self.namespaces.values {
            result.formUnion(Set(blockchain.accounts.compactMap { Int($0.reference) }))
        }

        return Array(result)
    }

}
