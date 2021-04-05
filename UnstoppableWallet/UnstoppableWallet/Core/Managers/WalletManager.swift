import RxSwift

class WalletManager {
    private let accountManager: IAccountManager
    private let storage: IWalletStorage
    private let kitCleaner: IKitCleaner

    private let disposeBag = DisposeBag()
    private let subject = PublishSubject<[Wallet]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)
    private var cachedWallets = [Wallet]()

    init(accountManager: IAccountManager, storage: IWalletStorage, kitCleaner: IKitCleaner) {
        self.accountManager = accountManager
        self.storage = storage
        self.kitCleaner = kitCleaner
    }

    private func notify() {
        subject.onNext(cachedWallets)
    }

}

extension WalletManager: IWalletManager {

    var wallets: [Wallet] {
        queue.sync { cachedWallets }
    }

    var walletsUpdatedObservable: Observable<[Wallet]> {
        subject.asObservable()
    }

    func preloadWallets() {
        let wallets = storage.wallets(accounts: accountManager.accounts)

        queue.async {
            self.cachedWallets = wallets
            self.notify()
        }
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        storage.handle(newWallets: newWallets, deletedWallets: deletedWallets)

        queue.async {
            self.cachedWallets.append(contentsOf: newWallets)
            self.cachedWallets.removeAll { deletedWallets.contains($0) }
            self.notify()
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
