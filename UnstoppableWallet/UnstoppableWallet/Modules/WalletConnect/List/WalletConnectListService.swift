import Foundation
import RxSwift
import RxRelay
import RxCocoa
import WalletConnectUtils
import WalletConnectSign
import WalletConnectPairing
import MarketKit

class WalletConnectListService {
    static let timeOutInterval: Int = 5

    private var disposeBag = DisposeBag()
    private var waitingForSessionDisposeBag = DisposeBag()
    private(set) var isWaitingForSession = false

    private let createServiceV1Relay = PublishRelay<WalletConnectV1MainService>()
    private let validateV2ResultRelay = PublishRelay<Result<String, Error>>()
    private let pairingV2ResultRelay = PublishRelay<Result<(), Error>>()
    private let proposalV2ReceivedRelay = PublishRelay<()>()
    private let proposalV2timeOutRelay = PublishRelay<()>()
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
                    appName: $0.peerMeta.name,
                    appUrl: $0.peerMeta.url,
                    appDescription: $0.peerMeta.description,
                    appIcons: $0.peerMeta.icons
            )
        }
    }

    private func items(sessions: [WalletConnectSign.Session]) -> [Item] {
        let pendingRequests = pendingRequestsV2

        return sessions.map { session in
            let blockchains = session.chainIds.compactMap { evmBlockchainManager.blockchain(chainId: $0) }
            let requestCount = pendingRequests.filter { $0.topic == session.topic }.count

            return ItemV2(
                    id: session.id,
                    blockchains: blockchains,
                    appName: session.peer.name,
                    appUrl: session.peer.url,
                    appDescription: session.peer.description,
                    appIcons: session.peer.icons,
                    requestCount: requestCount
            )
        }
    }

    private func waitingForSession() {
        pairingV2ResultRelay.accept(.success(()))
        isWaitingForSession = true

        subscribe(waitingForSessionDisposeBag, sessionManagerV2.service.receiveProposalObservable) { [weak self] _ in
            self?.waitingForSessionDisposeBag = DisposeBag()
            self?.isWaitingForSession = false
            self?.proposalV2ReceivedRelay.accept(())
        }

        let timeOutTimer = Observable.just(()).delay(.seconds(Self.timeOutInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

        subscribe(waitingForSessionDisposeBag, timeOutTimer) { [weak self] in
            self?.waitingForSessionDisposeBag = DisposeBag()
            self?.isWaitingForSession = false
            self?.proposalV2timeOutRelay.accept(())
        }
    }

}

extension WalletConnectListService {

    var emptySessionList: Bool {
        (sessionManager.sessions.count + sessionManagerV2.sessions.count) == 0
    }

    var emptyPairingList: Bool {
        sessionManagerV2.pairings.count == 0
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
        sessionManagerV2.activePendingRequestsObservable
    }

    var pairings: [WalletConnectPairing.Pairing] {
        sessionManagerV2.pairings
    }

    var pairingsObservable: Observable<[WalletConnectPairing.Pairing]> {
        sessionManagerV2.pairingsObservable
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
            let forceTimer = Observable.just(()).delay(.seconds(Self.timeOutInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

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

    var createServiceV1Observable: Observable<WalletConnectV1MainService> {
        createServiceV1Relay.asObservable()
    }

    var validateV2ResultObservable: Observable<Result<String, Error>> {
        validateV2ResultRelay.asObservable()
    }

    var pairingV2ResultObservable: Observable<Result<(), Error>> {
        pairingV2ResultRelay.asObservable()
    }

    var proposalV2ReceivedObservable: Observable<()> {
        proposalV2ReceivedRelay.asObservable()
    }

    var proposalV2timeOutObservable: Observable<()> {
        proposalV2timeOutRelay.asObservable()
    }

    var connectionErrorObservable: Observable<Error> {
        connectionErrorRelay.asObservable()
    }

    func connect(uri: String) {
        switch WalletConnectUriHandler.uriVersion(uri: uri) {
        case 1:
            WalletConnectUriHandler.createServiceV1(uri: uri)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] service in
                        self?.createServiceV1Relay.accept(service)
                    }, onError: { [weak self] error in
                        self?.connectionErrorRelay.accept(error)
                    })
                    .disposed(by: disposeBag)
        case 2:
            do {
                try WalletConnectUriHandler.validate(uri: uri)
                validateV2ResultRelay.accept(.success(uri))
            } catch {
                validateV2ResultRelay.accept(.failure(error))
            }
        default:
            connectionErrorRelay.accept(WalletConnectUriHandler.ConnectionError.wrongUri)
        }
    }

    func pairV2(validUri: String) {
        WalletConnectUriHandler.pairV2(uri: validUri)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] service in
                    self?.waitingForSession()
                }, onError: { [weak self] error in
                    self?.pairingV2ResultRelay.accept(.failure(error))
                })
                .disposed(by: disposeBag)
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

    class Item {
        let id: Int
        let blockchains: [MarketKit.Blockchain]

        let appName: String
        let appUrl: String
        let appDescription: String
        let appIcons: [String]

        init(id: Int, blockchains: [MarketKit.Blockchain], appName: String, appUrl: String, appDescription: String, appIcons: [String]) {
            self.id = id
            self.blockchains = blockchains
            self.appName = appName
            self.appUrl = appUrl
            self.appDescription = appDescription
            self.appIcons = appIcons
        }
    }

    class ItemV2: Item {
        let requestCount: Int

        init(id: Int, blockchains: [MarketKit.Blockchain], appName: String, appUrl: String, appDescription: String, appIcons: [String], requestCount: Int) {
            self.requestCount = requestCount
            super.init(id: id, blockchains: blockchains, appName: appName, appUrl: appUrl, appDescription: appDescription, appIcons: appIcons)
        }
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

        for blockchain in namespaces.values {
            result.formUnion(Set(blockchain.accounts.compactMap { Int($0.reference) }))
        }

        return Array(result)
    }

}
