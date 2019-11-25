import RxSwift

class WalletManager {
    private let accountManager: IAccountManager
    private let walletFactory: IWalletFactory
    private let storage: IWalletStorage
    private let cache: WalletsCache = WalletsCache()

    private let disposeBag = DisposeBag()
    private let walletsUpdatedSubject = PublishSubject<[Wallet]>()

    init(accountManager: IAccountManager, walletFactory: IWalletFactory, storage: IWalletStorage) {
        self.accountManager = accountManager
        self.walletFactory = walletFactory
        self.storage = storage
    }

    private func notify() {
        walletsUpdatedSubject.onNext(cache.wallets)
    }

}

extension WalletManager: IWalletManager {

    var wallets: [Wallet] {
        cache.wallets
    }

    var walletsUpdatedObservable: Observable<[Wallet]> {
        walletsUpdatedSubject.asObservable()
    }

    func wallet(coin: Coin) -> Wallet? {
        guard let account = accountManager.account(coinType: coin.type) else {
            return nil
        }

        return walletFactory.wallet(coin: coin, account: account, coinSettings: [:])
    }

    func preloadWallets() {
        let wallets = storage.wallets(accounts: accountManager.accounts)
        cache.wallets = wallets
        notify()
    }

    func save(wallets: [Wallet]) {
        storage.save(wallets: wallets)
        cache.append(wallets: wallets)
        notify()
    }

    func delete(wallets: [Wallet]) {
        storage.delete(wallets: wallets)
        cache.remove(wallets: wallets)
        notify()
    }

    func clearWallets() {
        storage.clearWallets()
    }

}

extension WalletManager {

    private class WalletsCache {
        private var array = [Wallet]()

        var wallets: [Wallet] {
            get {
                array
            }
            set {
                array = newValue
            }
        }

        func append(wallets: [Wallet]) {
            array.append(contentsOf: wallets)
        }

        func remove(wallets: [Wallet]) {
            array.removeAll { wallets.contains($0) }
        }

    }

}
