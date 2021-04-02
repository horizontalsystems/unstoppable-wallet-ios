import RxSwift

class WalletStorage {
    private let coinManager: ICoinManager
    private let storage: IEnabledWalletStorage

    init(coinManager: ICoinManager, storage: IEnabledWalletStorage) {
        self.coinManager = coinManager
        self.storage = storage
    }

    private func enabledWallet(wallet: Wallet) -> EnabledWallet {
        EnabledWallet(
                coinId: wallet.coin.id,
                coinSettingsId: wallet.configuredCoin.settings.id,
                accountId: wallet.account.id
        )
    }

}

extension WalletStorage: IWalletStorage {

    func wallets(accounts: [Account]) -> [Wallet] {
        let coins = coinManager.coins

        return storage.enabledWallets.compactMap { enabledWallet in
            guard let coin = coins.first(where: { $0.id == enabledWallet.coinId }) else {
                return nil
            }

            guard let account = accounts.first(where: { $0.id == enabledWallet.accountId }) else {
                return nil
            }

            let settings = CoinSettings(id: enabledWallet.coinSettingsId)
            let configuredCoin = ConfiguredCoin(coin: coin, settings: settings)

            return Wallet(configuredCoin: configuredCoin, account: account)
        }
    }

    func save(wallets: [Wallet]) {
        let enabledWallets = wallets.map { enabledWallet(wallet: $0) }
        storage.save(enabledWallets: enabledWallets)
    }

    func delete(wallets: [Wallet]) {
        let enabledWallets = wallets.map { enabledWallet(wallet: $0) }
        storage.delete(enabledWallets: enabledWallets)
    }

    func clearWallets() {
        storage.clearEnabledWallets()
    }

}
