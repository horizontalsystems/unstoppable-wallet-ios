import RxSwift

class WalletStorage {
    private let appConfigProvider: IAppConfigProvider
    private let walletFactory: IWalletFactory
    private let storage: IEnabledWalletStorage

    init(appConfigProvider: IAppConfigProvider, walletFactory: IWalletFactory, storage: IEnabledWalletStorage) {
        self.appConfigProvider = appConfigProvider
        self.walletFactory = walletFactory
        self.storage = storage
    }

}

extension WalletStorage: IWalletStorage {

    func wallets(accounts: [Account]) -> [Wallet] {
        let coins = appConfigProvider.coins

        return storage.enabledWallets.compactMap { enabledWallet in
            guard let coin = coins.first(where: { $0.code == enabledWallet.coinCode }) else {
                return nil
            }

            guard let account = accounts.first(where: { $0.id == enabledWallet.accountId }) else {
                return nil
            }

            return walletFactory.wallet(coin: coin, account: account, syncMode: enabledWallet.syncMode)
        }
    }

    func save(wallets: [Wallet]) {
        var enabledWallets = [EnabledWallet]()

        for (order, wallet) in wallets.enumerated() {
            enabledWallets.append(EnabledWallet(coinCode: wallet.coin.code, accountId: wallet.account.id, syncMode: wallet.syncMode, order: order))
        }

        storage.save(enabledWallets: enabledWallets)
    }

}
