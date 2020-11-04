import WalletConnect
import RxSwift
import RxRelay

class WalletConnectSessionStore {
    private let accountManager: IAccountManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    private let storedPeerMetaRelay = PublishRelay<WCPeerMeta?>()
    private let disposeBag = DisposeBag()

    init(accountManager: IAccountManager, predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
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

extension WalletConnectSessionStore {

    var storedItem: WCSessionStoreItem? {
        WCSessionStore.allSessions.first?.value
    }

    var storedPeerMeta: WCPeerMeta? {
        storedItem?.peerMeta
    }

    var storedPeerMetaObservable: Observable<WCPeerMeta?> {
        storedPeerMetaRelay.asObservable()
    }

    func store(session: WCSession, peerId: String, peerMeta: WCPeerMeta) {
        WCSessionStore.store(session, peerId: peerId, peerMeta: peerMeta)

        storedPeerMetaRelay.accept(peerMeta)
    }

    func clear() {
        WCSessionStore.clearAll()

        storedPeerMetaRelay.accept(nil)
    }

}
