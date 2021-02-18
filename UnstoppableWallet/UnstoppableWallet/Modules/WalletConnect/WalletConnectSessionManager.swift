import WalletConnect
import RxSwift
import RxRelay

class WalletConnectSessionManager {
    private let storage: IWalletConnectSessionStorage
    private let accountManager: IAccountManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    private let storedPeerMetaRelay = PublishRelay<WCPeerMeta?>()
    private let disposeBag = DisposeBag()

    init(storage: IWalletConnectSessionStorage, accountManager: IAccountManager, predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
        self.storage = storage
        self.accountManager = accountManager
        self.predefinedAccountTypeManager = predefinedAccountTypeManager

        accountManager.deleteAccountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] account in
                    self?.handleDeleted(account: account)
                })
                .disposed(by: disposeBag)
    }

    private func handleDeleted(account: Account) {
        // since there is no multi-account support yet, we delete WC stored session for account that satisfies Standard predefined account type

        guard let predefinedAccountType = predefinedAccountTypeManager.predefinedAccountType(accountType: account.type) else {
            return
        }

        guard predefinedAccountType == .standard else {
            return
        }

        clear()
    }

}

extension WalletConnectSessionManager {

    var storedSession: WalletConnectSession? {
        storage.sessions.first
    }

    var storedPeerMeta: WCPeerMeta? {
        storedSession?.peerMeta
    }

    var storedPeerMetaObservable: Observable<WCPeerMeta?> {
        storedPeerMetaRelay.asObservable()
    }

    func store(session: WalletConnectSession) {
        storage.save(session: session)
        storedPeerMetaRelay.accept(session.peerMeta)
    }

    func clear() {
        storage.deleteAll()
        storedPeerMetaRelay.accept(nil)
    }

}
