import RxSwift

class WalletManager {
    private let appConfigProvider: IAppConfigProvider
    private let storage: IEnabledWalletStorage

    private let disposeBag = DisposeBag()

    var wallets = [Wallet]() {
        didSet {
            walletsUpdatedSignal.notify()
        }
    }

    let walletsUpdatedSignal = Signal()

    init(appConfigProvider: IAppConfigProvider, storage: IEnabledWalletStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage

        storage.enabledWalletsObservable
                .subscribe(onNext: { [weak self] enabledCoins in
                    self?.handle(enabledWallets: enabledCoins)
                })
                .disposed(by: disposeBag)
    }

    private func handle(enabledWallets: [EnabledWallet]) {
        // todo: fetch accounts from secure storage
        let accounts = [Account]()

        wallets = enabledWallets.compactMap { enabledWallet in
            guard let coin = appConfigProvider.coins.first(where: { $0.code == enabledWallet.coinCode }) else {
                return nil
            }

            guard let account = accounts.first(where: { $0.name == enabledWallet.accountName }) else {
                return nil
            }

            return Wallet(coin: coin, account: account)
        }
    }

}

extension WalletManager: IWalletManager {

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

    func clear() {
        wallets = []
        storage.clearEnabledWallets()
    }

}
