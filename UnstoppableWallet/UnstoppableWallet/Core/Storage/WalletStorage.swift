import RxSwift
import MarketKit

class WalletStorage {
    private let marketKit: MarketKit.Kit
    private let storage: EnabledWalletStorage

    init(marketKit: MarketKit.Kit, storage: EnabledWalletStorage) {
        self.marketKit = marketKit
        self.storage = storage
    }

    private func enabledWallet(wallet: Wallet) -> EnabledWallet {
        EnabledWallet(
                coinId: wallet.platform.coinType.id,
                coinSettingsId: wallet.coinSettings.id,
                accountId: wallet.account.id,
                coinName: wallet.coin.name,
                coinCode: wallet.coin.code,
                coinDecimals: wallet.platform.decimals
        )
    }

}

extension WalletStorage {

    func wallets(account: Account) throws -> [Wallet] {
        let enabledWallets = try storage.enabledWallets(accountId: account.id)
        let coinTypeIds = enabledWallets.map { $0.coinId }
        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds)

        return enabledWallets.compactMap { enabledWallet in
            if let platformCoin = platformCoins.first(where: { $0.coinType.id == enabledWallet.coinId }) {
                let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
                let configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin, coinSettings: coinSettings)
                return Wallet(configuredPlatformCoin: configuredPlatformCoin, account: account)
            }

            if let coinName = enabledWallet.coinName, let coinCode = enabledWallet.coinCode, let coinDecimals = enabledWallet.coinDecimals {
                let coinSettings = CoinSettings(id: enabledWallet.coinSettingsId)
                let coinType = CoinType(id: enabledWallet.coinId)
                let coinUid = coinType.customCoinUid

                let platformCoin = PlatformCoin(
                        coin: Coin(uid: coinUid, name: coinName, code: coinCode),
                        platform: Platform(coinType: coinType, decimals: coinDecimals, coinUid: coinUid)
                )

                let configuredPlatformCoin = ConfiguredPlatformCoin(platformCoin: platformCoin, coinSettings: coinSettings)
                return Wallet(configuredPlatformCoin: configuredPlatformCoin, account: account)
            }

            return nil
        }
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        let newEnabledWallets = newWallets.map { enabledWallet(wallet: $0) }
        let deletedEnabledWallets = deletedWallets.map { enabledWallet(wallet: $0) }
        try? storage.handle(newEnabledWallets: newEnabledWallets, deletedEnabledWallets: deletedEnabledWallets)
    }

    func clearWallets() {
        try? storage.clear()
    }

}
