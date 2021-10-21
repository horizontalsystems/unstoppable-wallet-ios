import WalletConnectV1
import RxSwift
import RxRelay

class WalletConnectSessionManager {
    private let storage: IWalletConnectSessionStorage
    private let accountManager: IAccountManager
    private let accountSettingManager: AccountSettingManager
    private let disposeBag = DisposeBag()

    private let sessionsRelay = PublishRelay<[WalletConnectSession]>()

    init(storage: IWalletConnectSessionStorage, accountManager: IAccountManager, accountSettingManager: AccountSettingManager) {
        self.storage = storage
        self.accountManager = accountManager
        self.accountSettingManager = accountSettingManager

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

        subscribe(disposeBag, accountSettingManager.ethereumNetworkObservable) { [weak self] _, _ in self?.syncSessions() }
        subscribe(disposeBag, accountSettingManager.binanceSmartChainNetworkObservable) { [weak self] _, _ in self?.syncSessions() }
    }

    private func handleDeleted(account: Account) {
        storage.deleteSessions(accountId: account.id)
        syncSessions()
    }

    private func handle(activeAccount: Account?) {
        syncSessions()
    }

    private func syncSessions() {
        sessionsRelay.accept(sessions)
    }

}

extension WalletConnectSessionManager {

    var sessions: [WalletConnectSession] {
        guard let activeAccount = accountManager.activeAccount else {
            return []
        }

        let ethereumChainId = accountSettingManager.ethereumNetwork(account: activeAccount).networkType.chainId
        let binanceSmartChainChainId = accountSettingManager.binanceSmartChainNetwork(account: activeAccount).networkType.chainId

        return storage.sessions(accountId: activeAccount.id, chainIds: [ethereumChainId, binanceSmartChainChainId])
    }

    var sessionsObservable: Observable<[WalletConnectSession]> {
        sessionsRelay.asObservable()
    }

    func save(session: WalletConnectSession) {
        storage.save(session: session)
        syncSessions()
    }

    func deleteSession(peerId: String) {
        storage.deleteSession(peerId: peerId)
        syncSessions()
    }

}
