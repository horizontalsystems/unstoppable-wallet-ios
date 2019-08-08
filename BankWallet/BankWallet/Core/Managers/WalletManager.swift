import RxSwift

class WalletManager {
    private let accountManager: IAccountManager
    private let walletFactory: IWalletFactory
    private let storage: IWalletStorage
    private let cache: WalletsCache = WalletsCache()

    private let disposeBag = DisposeBag()
    let walletsUpdatedSignal = Signal()

    init(accountManager: IAccountManager, walletFactory: IWalletFactory, storage: IWalletStorage) {
        self.accountManager = accountManager
        self.walletFactory = walletFactory
        self.storage = storage
    }

}

extension WalletManager: IWalletManager {

    var wallets: [Wallet] {
        return cache.wallets
    }

    func wallet(coin: Coin) -> Wallet? {
        guard let account = accountManager.account(coinType: coin.type) else {
            return nil
        }

        return walletFactory.wallet(coin: coin, account: account, syncMode: account.defaultSyncMode)
    }

    func preloadWallets() {
        cache.set(wallets: storage.wallets(accounts: accountManager.accounts))
    }

    func enable(wallets: [Wallet]) {
        storage.save(wallets: wallets)
        cache.set(wallets: wallets)
        walletsUpdatedSignal.notify()
    }

}

extension WalletManager {

    private class WalletsCache {
        private var array = [Wallet]()

        var wallets: [Wallet] {
            return array
        }

        func set(wallets: [Wallet]) {
            array = wallets
        }
    }

}
