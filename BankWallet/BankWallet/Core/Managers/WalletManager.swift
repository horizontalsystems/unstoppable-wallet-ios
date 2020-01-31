import RxSwift

class WalletManager {
    private let accountManager: IAccountManager
    private let walletFactory: IWalletFactory
    private let storage: IWalletStorage
    private let kitCleaner: IKitCleaner

    private let disposeBag = DisposeBag()
    private let subject = PublishSubject<[Wallet]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)
    private var cachedWallets = [Wallet]()

    init(accountManager: IAccountManager, walletFactory: IWalletFactory, storage: IWalletStorage, kitCleaner: IKitCleaner) {
        self.accountManager = accountManager
        self.walletFactory = walletFactory
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

    func save(wallets: [Wallet]) {
        storage.save(wallets: wallets)

        queue.async {
            self.cachedWallets.append(contentsOf: wallets)
            self.notify()
        }
    }

    func update(derivation: MnemonicDerivation, in wallets: [Wallet]) {
        delete(wallets: wallets)

        let wallets: [Wallet] = wallets.map {
            var coinSettings = $0.coinSettings
            coinSettings[CoinSetting.derivation] = derivation

            return Wallet(coin: $0.coin, account: $0.account, coinSettings: coinSettings)
        }

        save(wallets: wallets)
        kitCleaner.clear()
    }

    func update(syncMode: SyncMode, in wallets: [Wallet]) {
        delete(wallets: wallets)

        let wallets: [Wallet] = wallets.map {
            var coinSettings = $0.coinSettings
            coinSettings[CoinSetting.syncMode] = syncMode

            return Wallet(coin: $0.coin, account: $0.account, coinSettings: coinSettings)
        }

        save(wallets: wallets)
        kitCleaner.clear()
    }

    func delete(wallets: [Wallet]) {
        storage.delete(wallets: wallets)

        queue.async {
            self.cachedWallets.removeAll { wallets.contains($0) }
            self.notify()
        }
    }

    func clearWallets() {
        storage.clearWallets()
    }

}
