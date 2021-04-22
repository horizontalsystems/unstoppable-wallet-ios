import RxSwift
import RxRelay

class WalletManager {
    private let accountManager: IAccountManager
    private let storage: IWalletStorage
    private let kitCleaner: IKitCleaner
    private let disposeBag = DisposeBag()

    private let subject = PublishSubject<[Wallet]>()
    private let activeWalletsRelay = PublishRelay<[Wallet]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)
    private let activeWalletsQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager.active_wallets", qos: .userInitiated)

    private var cachedWallets = [Wallet]()
    private var cachedActiveWallets = [Wallet]()

    init(accountManager: IAccountManager, storage: IWalletStorage, kitCleaner: IKitCleaner) {
        self.accountManager = accountManager
        self.storage = storage
        self.kitCleaner = kitCleaner

        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] in self?.handleUpdate(activeAccount: $0) }
    }

    private func notify() {
        subject.onNext(cachedWallets)
    }

    private func notifyActiveWallets() {
        activeWalletsRelay.accept(cachedActiveWallets)
    }

    private func handleUpdate(activeAccount: Account?) {
        let activeWallets = activeAccount.map { storage.wallets(account: $0) } ?? []

        queue.async {
            self.cachedActiveWallets = activeWallets
            self.notifyActiveWallets()
        }
    }

}

extension WalletManager: IWalletManager {

    var activeWallets: [Wallet] {
        activeWalletsQueue.sync { cachedActiveWallets }
    }

    var activeWalletsUpdatedObservable: Observable<[Wallet]> {
        activeWalletsRelay.asObservable()
    }

    var wallets: [Wallet] {
        queue.sync { cachedWallets }
    }

    var walletsUpdatedObservable: Observable<[Wallet]> {
        subject.asObservable()
    }

    func preloadWallets() {
        let wallets = storage.wallets(accounts: accountManager.accounts)
        let activeWallets = accountManager.activeAccount.map { storage.wallets(account: $0) } ?? []

        queue.async {
            self.cachedWallets = wallets
            self.notify()

            self.cachedActiveWallets = activeWallets
            self.notifyActiveWallets()
        }
    }

    func wallets(account: Account) -> [Wallet] {
        storage.wallets(account: account)
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        storage.handle(newWallets: newWallets, deletedWallets: deletedWallets)

        queue.async {
            self.cachedWallets.append(contentsOf: newWallets)
            self.cachedWallets.removeAll { deletedWallets.contains($0) }
            self.notify()

            let activeAccount = self.accountManager.activeAccount
            self.cachedActiveWallets.append(contentsOf: newWallets.filter { $0.account == activeAccount })
            self.cachedActiveWallets.removeAll { deletedWallets.contains($0) }
            self.notifyActiveWallets()
        }
    }

    func save(wallets: [Wallet]) {
        handle(newWallets: wallets, deletedWallets: [])
    }

    func delete(wallets: [Wallet]) {
        handle(newWallets: [], deletedWallets: wallets)
    }

    func clearWallets() {
        storage.clearWallets()
    }

}
