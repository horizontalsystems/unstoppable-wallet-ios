import WalletConnectV1
import RxSwift
import RxRelay

class WalletConnectSessionManager {
    private let storage: WalletConnectSessionStorage
    private let accountManager: AccountManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let disposeBag = DisposeBag()

    private let sessionsRelay = BehaviorRelay<[WalletConnectSession]>(value: [])

    init(storage: WalletConnectSessionStorage, accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager) {
        self.storage = storage
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager

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

        syncSessions()
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

    private func isChainIdsEnabled(chainId: Int) -> Bool {
        evmBlockchainManager.blockchain(chainId: chainId) != nil
    }

}

extension WalletConnectSessionManager {

    var sessions: [WalletConnectSession] {
        guard let activeAccount = accountManager.activeAccount else {
            return []
        }

        return storage.sessions(accountId: activeAccount.id).filter { session in
            isChainIdsEnabled(chainId: session.chainId)
        }
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
