import WalletConnect
import WalletConnectUtils
import RxSwift
import RxCocoa

class WalletConnectV2SessionManager {
    private let disposeBag = DisposeBag()

    let service: WalletConnectV2Service
    private let storage: IWalletConnectV2SessionStorage
    private let accountManager: IAccountManager
    private let currentDateProvider: ICurrentDateProvider

    private let sessionsRelay = BehaviorRelay<[Session]>(value: [])
    private let pendingRequestsRelay = BehaviorRelay<[Request]>(value: [])
    private let sessionRequestReceivedRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectV2Service, storage: IWalletConnectV2SessionStorage, accountManager: IAccountManager, currentDateProvider: ICurrentDateProvider) {
        self.service = service
        self.storage = storage
        self.accountManager = accountManager
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

        syncSessions()
    }

    private func handleDeleted(account: Account) {
        storage.deleteSessionsV2(accountId: account.id)
        syncSessions()
    }

    private func handle(activeAccount: Account?) {
        syncSessions()
    }

    private func syncSessions() {
        guard let accountId = accountManager.activeAccount?.id else {
            return
        }

        let currentSessions = service.activeSessions
        let allDbSessions = storage.sessionsV2(accountId: nil)
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
            WalletConnectV2Session(accountId: accountId, topic: $0.topic)
        })
        storage.deleteSessionV2(topics: deletedTopics)

        sessionsRelay.accept(sessions(accountId: accountId, sessions: currentSessions))
        pendingRequestsRelay.accept(requests())
    }

    private func receiveSession(request: Request) {
        guard let accountId = accountManager.activeAccount?.id else {
            return
        }
        let activeSessions = storage.sessionsV2(accountId: accountId)

        guard activeSessions.first(where: { session in session.topic == request.topic }) != nil,
              let session = allSessions.first(where: { session in session.topic == request.topic }),
              let request = try? WalletConnectV2RequestMapper.map(dAppName: session.peer.name, request: request) else {
            return
        }

        sessionRequestReceivedRelay.accept(request)
    }

    private func sessions(accountId: String, sessions: [Session]?) -> [Session] {
        let sessions = sessions ?? service.activeSessions
        let dbSessions = storage.sessionsV2(accountId: accountId)

        let accountSessions = sessions.filter { session in
            dbSessions.contains {
                $0.topic == session.topic
            }
        }

        return accountSessions
    }

    private func syncPendingRequest() {
        pendingRequestsRelay.accept(requests())
    }

    private func requests(accountId: String? = nil) -> [Request] {
        let allRequests = service.pendingRequests
        let dbSessions = storage.sessionsV2(accountId: accountId)

        return allRequests.filter { request in
            dbSessions.contains { session in
                session.topic == request.topic
            }
        }
    }

}

extension WalletConnectV2SessionManager {

    public var sessions: [Session] {
        guard let accountId = accountManager.activeAccount?.id else {
            return []
        }

        return sessions(accountId: accountId, sessions: nil)
    }

    public var allSessions: [Session] {
        service.activeSessions
    }

    public var sessionsObservable: Observable<[Session]> {
        sessionsRelay.asObservable()
    }

    public func deleteSession(topic: String) {
        service.disconnect(topic: topic, reason: Reason(code: 1, message: "Session Killed by User"))
    }

    public func pendingRequests(accountId: String? = nil) -> [Request] {
        requests(accountId: accountId)
    }

    public var pendingRequestsObservable: Observable<[Request]> {
        pendingRequestsRelay.asObservable()
    }

    public var sessionRequestReceivedObservable: Observable<WalletConnectRequest> {
        sessionRequestReceivedRelay.asObservable()
    }

}
