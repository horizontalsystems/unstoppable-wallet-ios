import RxSwift
import MarketKit

class WalletStorageNew {
    private let coinManager: CoinManagerNew
    private let storage: IEnabledWalletStorage

    init(coinManager: CoinManagerNew, storage: IEnabledWalletStorage) {
        self.coinManager = coinManager
        self.storage = storage
    }

    private func enabledWallet(wallet: WalletNew) -> EnabledWallet {
        EnabledWallet(
                coinId: wallet.platform.coinType.id,
                coinSettingsId: wallet.coinSettings.id,
                accountId: wallet.account.id
        )
    }

}

extension WalletStorageNew {

    func wallets(account: Account) throws -> [WalletNew] {
        let enabledWallets = storage.enabledWallets(accountId: account.id)
        let coinTypeIds = enabledWallets.map { $0.coinId }
        let platformCoins = try coinManager.platformCoins(coinTypeIds: coinTypeIds)

        return enabledWallets.compactMap { enabledWallet in
            guard let platformCoin = platformCoins.first(where: { $0.coinType.id == enabledWallet.coinId }) else {
                return nil
            }

            let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
            let configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin, coinSettings: coinSettings)
            return WalletNew(configuredPlatformCoin: configuredPlatformCoin, account: account)
        }
    }

    func handle(newWallets: [WalletNew], deletedWallets: [WalletNew]) {
        let newEnabledWallets = newWallets.map { enabledWallet(wallet: $0) }
        let deletedEnabledWallets = deletedWallets.map { enabledWallet(wallet: $0) }
        storage.handle(newEnabledWallets: newEnabledWallets, deletedEnabledWallets: deletedEnabledWallets)
    }

    func clearWallets() {
        storage.clearEnabledWallets()
    }

}
