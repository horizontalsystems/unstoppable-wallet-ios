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

        accountManager.deleteAccountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] account in
                    self?.handleDeleted(account: account)
                })
                .disposed(by: disposeBag)
    }

    private func handleDeleted(account: Account) {
        storage.deleteSession(accountId: account.id)
        sessionsRelay.accept(sessions)
    }

}

extension WalletConnectSessionManager {

    var sessions: [WalletConnectSession] {
        storage.sessions
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
