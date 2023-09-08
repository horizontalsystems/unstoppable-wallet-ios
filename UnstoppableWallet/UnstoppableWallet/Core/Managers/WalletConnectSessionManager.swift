import MarketKit
import RxCocoa
import RxSwift
import WalletConnectPairing
import WalletConnectSign
import WalletConnectUtils

class WalletConnectSessionManager {
    private let disposeBag = DisposeBag()

    let service: WalletConnectService
    private let storage: WalletConnectSessionStorage
    private let accountManager: AccountManager
    private let currentDateProvider: CurrentDateProvider
    private let evmBlockchainManager: EvmBlockchainManager

    private let sessionsRelay = BehaviorRelay<[WalletConnectSign.Session]>(value: [])
    private let activePendingRequestsRelay = BehaviorRelay<[WalletConnectSign.Request]>(value: [])
    private let pairingsRelay = BehaviorRelay<[WalletConnectPairing.Pairing]>(value: [])
    private let sessionRequestReceivedRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectService, storage: WalletConnectSessionStorage, accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager, currentDateProvider: CurrentDateProvider) {
        self.service = service
        self.storage = storage
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager
        self.currentDateProvider = currentDateProvider

        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in
            self?.handleDeleted(account: $0)
        }
        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] in
            self?.handle(activeAccount: $0)
        }
        subscribe(disposeBag, service.sessionsUpdatedObservable) { [weak self] in
            self?.syncSessions()
        }
        subscribe(disposeBag, service.sessionRequestReceivedObservable) { [weak self] in
            self?.receiveSession(request: $0)
        }
        subscribe(disposeBag, service.pendingRequestsUpdatedObservable) { [weak self] in
            self?.syncPendingRequest()
        }
        subscribe(disposeBag, service.pairingUpdatedObservable) { [weak self] in
            self?.syncPairings()
        }

        syncSessions()
        syncPairings()
    }

    private func handleDeleted(account: Account) {
        storage.deleteSessions(accountId: account.id)
        syncSessions()
        syncPendingRequest()
    }

    private func handle(activeAccount _: Account?) {
        syncSessions()
        syncPendingRequest()
    }

    private func syncSessions() {
        guard let accountId = accountManager.activeAccount?.id else {
            return
        }

        let currentSessions = allSessions
        let allDbSessions = storage.sessions(accountId: nil)
        let dbTopics = allDbSessions.map {
            $0.topic
        }

        let newSessions = currentSessions.filter { session in
            !dbTopics.contains(session.topic)
        }
        let deletedTopics = dbTopics.filter { topic in
            !currentSessions.contains {
                $0.topic == topic
            }
        }

        storage.save(sessions: newSessions.map {
            WalletConnectSession(accountId: accountId, topic: $0.topic)
        })
        storage.deleteSession(topics: deletedTopics)

        sessionsRelay.accept(sessions(accountId: accountId, sessions: currentSessions))
        activePendingRequestsRelay.accept(activePendingRequests)
    }

    private func receiveSession(request: WalletConnectSign.Request) {
        guard let account = accountManager.activeAccount else {
            return
        }
        let activeSessions = storage.sessions(accountId: account.id)

        guard let chainId = Int(request.chainId.reference),
              let blockchain = evmBlockchainManager.blockchain(chainId: chainId),
              let address = try? WalletConnectManager.evmAddress(
                  account: account,
                  chain: evmBlockchainManager.chain(blockchainType: blockchain.type)
              )
        else {
            return
        }

        let chain = WalletConnectRequest.Chain(id: chainId, chainName: blockchain.name, address: address.eip55)
        guard activeSessions.first(where: { session in session.topic == request.topic }) != nil,
              let session = allSessions.first(where: { session in session.topic == request.topic }),
              let request = try? WalletConnectRequestMapper.map(dAppName: session.peer.name, chain: chain, request: request)
        else {
            return
        }

        sessionRequestReceivedRelay.accept(request)
    }

    private func sessions(accountId: String, sessions: [WalletConnectSign.Session]?) -> [WalletConnectSign.Session] {
        let sessions = sessions ?? allSessions
        let dbSessions = storage.sessions(accountId: accountId)

        let accountSessions = sessions.filter { session in
            dbSessions.contains {
                $0.topic == session.topic
            }
        }

        return accountSessions
    }

    private func syncPendingRequest() {
        activePendingRequestsRelay.accept(activePendingRequests)
    }

    private func syncPairings() {
        pairingsRelay.accept(service.pairings)
    }

    private func isChainIdsEnabled(chainIds: [Int]) -> Bool {
        chainIds.allSatisfy { id in
            evmBlockchainManager.blockchain(chainId: id) != nil
        }
    }

    private func requests(accountId: String? = nil) -> [WalletConnectSign.Request] {
        let allRequests = service.pendingRequests
        let dbSessions = storage.sessions(accountId: accountId)

        return allRequests.filter { request in
            dbSessions.contains { session in
                session.topic == request.topic
            }
        }
    }
}

extension WalletConnectSessionManager {
    public func validate(uri: String) throws {
        _ = try service.validate(uri: uri)
    }

    public var sessions: [WalletConnectSign.Session] {
        guard let accountId = accountManager.activeAccount?.id else {
            return []
        }

        return sessions(accountId: accountId, sessions: nil)
    }

    public var allSessions: [WalletConnectSign.Session] {
        service.activeSessions.filter { session in
            isChainIdsEnabled(chainIds: session.chainIds)
        }
    }

    public var sessionsObservable: Observable<[WalletConnectSign.Session]> {
        sessionsRelay.asObservable()
    }

    public func deleteSession(topic: String) {
        service.disconnect(topic: topic, reason: WalletConnectMainService.RejectionReason(code: 1, message: "Session Killed by User"))
    }

    public var activePendingRequests: [WalletConnectSign.Request] {
        guard let accountId = accountManager.activeAccount?.id else {
            return []
        }

        return pendingRequests(accountId: accountId)
    }

    public func pendingRequests(accountId: String? = nil) -> [WalletConnectSign.Request] {
        requests(accountId: accountId)
    }

    public var activePendingRequestsObservable: Observable<[WalletConnectSign.Request]> {
        activePendingRequestsRelay.asObservable()
    }

    public var pairings: [WalletConnectPairing.Pairing] {
        service.pairings
    }

    public var pairingsObservable: Observable<[WalletConnectPairing.Pairing]> {
        pairingsRelay.asObservable()
    }

    public var sessionRequestReceivedObservable: Observable<WalletConnectRequest> {
        sessionRequestReceivedRelay.asObservable()
    }

    public func disconnectPairing(topic: String) -> Single<Void> {
        service.disconnectPairing(topic: topic)
    }
}
