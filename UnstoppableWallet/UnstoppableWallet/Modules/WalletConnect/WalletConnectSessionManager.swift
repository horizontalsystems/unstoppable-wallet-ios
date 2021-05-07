import WalletConnect
import RxSwift
import RxRelay

class WalletConnectSessionManager {
    private let storage: IWalletConnectSessionStorage
    private let accountManager: IAccountManager
    private let disposeBag = DisposeBag()

    private let sessionsRelay = PublishRelay<[WalletConnectSession]>()

    init(storage: IWalletConnectSessionStorage, accountManager: IAccountManager) {
        self.storage = storage
        self.accountManager = accountManager

        accountManager.accountDeletedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] account in
                    self?.handleDeleted(account: account)
                })
                .disposed(by: disposeBag)

        accountManager.activeAccountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] activeAccount in
                    self?.handle(activeAccount: activeAccount)
                })
                .disposed(by: disposeBag)
    }

    private func handleDeleted(account: Account) {
        storage.deleteSessions(accountId: account.id)
        sessionsRelay.accept(sessions)
    }

    private func handle(activeAccount: Account?) {
        sessionsRelay.accept(sessions)
    }

}

extension WalletConnectSessionManager {

    var sessions: [WalletConnectSession] {
        guard let activeAccount = accountManager.activeAccount else {
            return []
        }

        return storage.sessions(accountId: activeAccount.id)
    }

    var sessionsObservable: Observable<[WalletConnectSession]> {
        sessionsRelay.asObservable()
    }

    func save(session: WalletConnectSession) {
        storage.save(session: session)
        sessionsRelay.accept(sessions)
    }

    func deleteSession(peerId: String) {
        storage.deleteSession(peerId: peerId)
        sessionsRelay.accept(sessions)
    }

}
