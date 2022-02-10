import WalletConnect
import WalletConnectUtils
import RxSwift
import RxCocoa

class WalletConnectV2SessionManager {
    private let disposeBag = DisposeBag()

    let service: WalletConnectV2Service
//    private let storage: IWalletConnectV2SessionStorage
    private let accountManager: IAccountManager
    private let currentDateProvider: ICurrentDateProvider

    private let sessionsRelay = BehaviorRelay<[Session]>(value: [])

    init(service: WalletConnectV2Service, accountManager: IAccountManager, currentDateProvider: ICurrentDateProvider) {
        self.service = service
//        self.storage = storage
        self.accountManager = accountManager
        self.currentDateProvider = currentDateProvider

        sessionsRelay.accept(service.activeSessions)
        subscribe(disposeBag, service.sessionsUpdatedObservable) { [weak self] in self?.sync(sessions: nil) }
    }

    private func sync(sessions: [Session]?) {
        print("Sync sessions v2!")
        sessionsRelay.accept(self.sessions)
    }

//    private func record(session: Session) -> WalletConnectV2SessionRecord? {
//        guard let activeAccount = accountManager.activeAccount else {
//            return nil
//        }
//
//        return WalletConnectV2SessionRecord(
//                accountId: activeAccount.id,
//                topic: session.topic,
//                updatedAt: currentDateProvider.currentDate
//        )
//    }

}

extension WalletConnectV2SessionManager {

    public var sessions: [Session] {
        service.activeSessions
    }

    public var sessionsObservable: Observable<[Session]> {
        sessionsRelay.asObservable()
    }

    public func deleteSession(topic: String) {
//        storage.deleteSessionV2(topic: topic)

        service.disconnect(topic: topic, reason: Reason(code: 1, message: "Session Killed by User"))
    }

}
