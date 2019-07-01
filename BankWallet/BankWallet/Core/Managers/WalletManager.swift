import RxSwift

class WalletManager {
    private let appConfigProvider: IAppConfigProvider
    private let accountManager: IAccountManager
    private let storage: IEnabledWalletStorage

    private let disposeBag = DisposeBag()

    var wallets = [Wallet]()
    let walletsUpdatedSignal = Signal()

    init(appConfigProvider: IAppConfigProvider, accountManager: IAccountManager, storage: IEnabledWalletStorage) {
        self.appConfigProvider = appConfigProvider
        self.accountManager = accountManager
        self.storage = storage

        accountManager.accountsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] accounts in
                    self?.handle(accounts: accounts)
                })
                .disposed(by: disposeBag)

        wallets = wallets(enabledWallets: storage.enabledWallets, accounts: accountManager.accounts)
    }

    private func handle(accounts: [Account]) {
        enable(wallets: wallets.filter { accounts.contains($0.account) })
    }

    private func wallets(enabledWallets: [EnabledWallet], accounts: [Account]) -> [Wallet] {
        return enabledWallets.compactMap { enabledWallet in
            guard let coin = appConfigProvider.coins.first(where: { $0.code == enabledWallet.coinCode }) else {
                return nil
            }

            guard let account = accounts.first(where: { $0.name == enabledWallet.accountName }) else {
                return nil
            }

            return Wallet(coin: coin, account: account, syncMode: enabledWallet.syncMode)
        }
    }

}

extension WalletManager: IWalletManager {

    func enable(wallets: [Wallet]) {
        var enabledWallets = [EnabledWallet]()

        for (order, wallet) in wallets.enumerated() {
            enabledWallets.append(EnabledWallet(coinCode: wallet.coin.code, accountName: wallet.account.name, syncMode: wallet.syncMode, order: order))
        }

        storage.save(enabledWallets: enabledWallets)

        self.wallets = wallets
        walletsUpdatedSignal.notify()
    }

    func enableDefaultWallets() {
        // todo: implement this

//        var enabledWallets = [EnabledWallet]()
//
//        for (order, coinCode) in appConfigProvider.defaultCoinCodes.enumerated() {
//            enabledWallets.append(EnabledCoin(coinCode: coinCode, order: order))
//        }
//
//        storage.save(enabledWallets: enabledWallets)
    }

}
