import RxSwift
import MarketKit

class WalletStorageNew {
    private let coinManager: CoinManagerNew
    private let storage: IEnabledWalletStorageNew

    init(coinManager: CoinManagerNew, storage: IEnabledWalletStorageNew) {
        self.coinManager = coinManager
        self.storage = storage
    }

    private func enabledWallet(wallet: WalletNew) -> EnabledWalletNew {
        EnabledWalletNew(
                coinUid: wallet.coin.uid,
                coinTypeId: wallet.platform.coinType.id,
                coinSettingsId: wallet.coinSettings.id,
                accountId: wallet.account.id
        )
    }

}

extension WalletStorageNew {

    func wallets(account: Account) throws -> [WalletNew] {
        let enabledWallets = storage.enabledWalletsNew(accountId: account.id)
        let coinUids = enabledWallets.map { $0.coinUid }
        let marketCoins = try coinManager.marketCoins(coinUids: coinUids)

        return enabledWallets.compactMap { enabledWallet in
            guard let marketCoin = marketCoins.first(where: { $0.coin.uid == enabledWallet.coinUid }) else {
                return nil
            }

            guard let platform = marketCoin.platforms.first(where: { $0.coinType.id == enabledWallet.coinTypeId }) else {
                return nil
            }

            let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
            let platformCoin = PlatformCoin(coin: marketCoin.coin, platform: platform)
            let configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin, settings: coinSettings)
            return WalletNew(configuredPlatformCoin: configuredPlatformCoin, account: account)
        }
    }

    func handle(newWallets: [WalletNew], deletedWallets: [WalletNew]) {
        let newEnabledWallets = newWallets.map { enabledWallet(wallet: $0) }
        let deletedEnabledWallets = deletedWallets.map { enabledWallet(wallet: $0) }
        storage.handle(newEnabledWalletsNew: newEnabledWallets, deletedEnabledWalletsNew: deletedEnabledWallets)
    }

    func clearWallets() {
        storage.clearEnabledWalletsNew()
    }

}
