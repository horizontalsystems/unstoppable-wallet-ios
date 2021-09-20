import RxSwift
import MarketKit

class WalletStorage {
    private let coinManager: CoinManager
    private let storage: IEnabledWalletStorage

    init(coinManager: CoinManager, storage: IEnabledWalletStorage) {
        self.coinManager = coinManager
        self.storage = storage
    }

    private func enabledWallet(wallet: Wallet) -> EnabledWallet {
        EnabledWallet(
                coinId: wallet.platform.coinType.id,
                coinSettingsId: wallet.coinSettings.id,
                accountId: wallet.account.id
        )
    }

}

extension WalletStorage {

    func wallets(account: Account) throws -> [Wallet] {
        let enabledWallets = storage.enabledWallets(accountId: account.id)
        let coinTypeIds = enabledWallets.map { $0.coinId }
        let platformCoins = try coinManager.platformCoins(coinTypeIds: coinTypeIds)

        return enabledWallets.compactMap { enabledWallet in
            guard let platformCoin = platformCoins.first(where: { $0.coinType.id == enabledWallet.coinId }) else {
                return nil
            }

            let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
            let configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin, coinSettings: coinSettings)
            return Wallet(configuredPlatformCoin: configuredPlatformCoin, account: account)
        }
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        let newEnabledWallets = newWallets.map { enabledWallet(wallet: $0) }
        let deletedEnabledWallets = deletedWallets.map { enabledWallet(wallet: $0) }
        storage.handle(newEnabledWallets: newEnabledWallets, deletedEnabledWallets: deletedEnabledWallets)
    }

    func clearWallets() {
        storage.clearEnabledWallets()
    }

}
