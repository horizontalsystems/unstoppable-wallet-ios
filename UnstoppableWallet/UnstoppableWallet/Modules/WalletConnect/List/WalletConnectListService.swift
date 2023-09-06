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

    private let validateResultRelay = PublishRelay<Result<String, Error>>()
    private let pairingResultRelay = PublishRelay<Result<(), Error>>()
    private let proposalReceivedRelay = PublishRelay<()>()
    private let proposalTimeOutRelay = PublishRelay<()>()
    private let connectionErrorRelay = PublishRelay<Error>()

    private let sessionManager: WalletConnectSessionManager
    private let evmBlockchainManager: EvmBlockchainManager

    private let showSessionRelay = PublishRelay<WalletConnectSign.Session>()
    private let sessionKillingRelay = PublishRelay<SessionKillingState>()

    init(sessionManager: WalletConnectSessionManager, evmBlockchainManager: EvmBlockchainManager) {
        self.sessionManager = sessionManager
        self.evmBlockchainManager = evmBlockchainManager
    }

    private func items(sessions: [WalletConnectSign.Session]) -> [Item] {
        let pendingRequests = pendingRequests

        return sessions.map { session in
            let blockchains = session.chainIds.compactMap { evmBlockchainManager.blockchain(chainId: $0) }
            let requestCount = pendingRequests.filter { $0.topic == session.topic }.count

            return Item(
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
        pairingResultRelay.accept(.success(()))
        isWaitingForSession = true

        subscribe(waitingForSessionDisposeBag, sessionManager.service.receiveProposalObservable) { [weak self] _ in
            self?.waitingForSessionDisposeBag = DisposeBag()
            self?.isWaitingForSession = false
            self?.proposalReceivedRelay.accept(())
        }

        let timeOutTimer = Observable.just(()).delay(.seconds(Self.timeOutInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

        subscribe(waitingForSessionDisposeBag, timeOutTimer) { [weak self] in
            self?.waitingForSessionDisposeBag = DisposeBag()
            self?.isWaitingForSession = false
            self?.proposalTimeOutRelay.accept(())
        }
    }

}

extension WalletConnectListService {

    var emptySessionList: Bool {
        sessionManager.sessions.isEmpty
    }

    var emptyPairingList: Bool {
        sessionManager.pairings.isEmpty
    }

    var items: [Item] {
        items(sessions: sessionManager.sessions)
    }

    var itemsObservable: Observable<[Item]> {
        sessionManager.sessionsObservable.map { [weak self] in
            self?.items(sessions: $0) ?? []
        }
    }

    var pendingRequests: [WalletConnectSign.Request] {
        sessionManager.pendingRequests()
    }

    var pendingRequestsObservable: Observable<[WalletConnectSign.Request]> {
        sessionManager.activePendingRequestsObservable
    }

    var pairings: [WalletConnectPairing.Pairing] {
        sessionManager.pairings
    }

    var pairingsObservable: Observable<[WalletConnectPairing.Pairing]> {
        sessionManager.pairingsObservable
    }

    var showSessionObservable: Observable<WalletConnectSign.Session> {
        showSessionRelay.asObservable()
    }

    var sessionKillingObservable: Observable<SessionKillingState> {
        sessionKillingRelay.asObservable()
    }

    func kill(id: Int) {
        if let session = sessionManager.sessions.first(where: { $0.id == id }) {
            sessionKillingRelay.accept(.processing)
            let killTimer = Observable.just(()).delay(.milliseconds(600), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            subscribe(disposeBag, killTimer) { [weak self] in
                self?.sessionManager.deleteSession(topic: session.topic)
                self?.sessionKillingRelay.accept(.completed)
            }
        }
    }

    var validateResultObservable: Observable<Result<String, Error>> {
        validateResultRelay.asObservable()
    }

    var pairingResultObservable: Observable<Result<(), Error>> {
        pairingResultRelay.asObservable()
    }

    var proposalReceivedObservable: Observable<()> {
        proposalReceivedRelay.asObservable()
    }

    var proposalTimeOutObservable: Observable<()> {
        proposalTimeOutRelay.asObservable()
    }

    var connectionErrorObservable: Observable<Error> {
        connectionErrorRelay.asObservable()
    }

    func connect(uri: String) {
        switch WalletConnectUriHandler.uriVersion(uri: uri) {
        case 2:
            do {
                try WalletConnectUriHandler.validate(uri: uri)
                validateResultRelay.accept(.success(uri))
            } catch {
                validateResultRelay.accept(.failure(error))
            }
        default:
            connectionErrorRelay.accept(WalletConnectUriHandler.ConnectionError.wrongUri)
        }
    }

    func pair(validUri: String) {
        WalletConnectUriHandler.pair(uri: validUri)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] service in
                    self?.waitingForSession()
                }, onError: { [weak self] error in
                    self?.pairingResultRelay.accept(.failure(error))
                })
                .disposed(by: disposeBag)
    }

    func showSession(id: Int) {
        if let session = sessionManager.sessions.first(where: { $0.id == id }) {
            showSessionRelay.accept(session)
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

        let requestCount: Int

        init(id: Int, blockchains: [MarketKit.Blockchain], appName: String, appUrl: String, appDescription: String, appIcons: [String], requestCount: Int) {
            self.id = id
            self.blockchains = blockchains
            self.appName = appName
            self.appUrl = appUrl
            self.appDescription = appDescription
            self.appIcons = appIcons
            self.requestCount = requestCount
        }
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
