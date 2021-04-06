import CoinKit

class InitialSyncSettingsManager {
    private let supportedCoinTypes = [
        SupportedCoinType(coinType: .bitcoin, defaultSyncMode: .fast, changeable: true),
        SupportedCoinType(coinType: .bitcoinCash, defaultSyncMode: .fast, changeable: true),
        SupportedCoinType(coinType: .dash, defaultSyncMode: .fast, changeable: true),
        SupportedCoinType(coinType: .litecoin, defaultSyncMode: .fast, changeable: true),
    ]

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let coinKit: CoinKit.Kit
    private let storage: IBlockchainSettingsStorage

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, coinKit: CoinKit.Kit, storage: IBlockchainSettingsStorage) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.coinKit = coinKit
        self.storage = storage
    }

    private func defaultSetting(supportedCoinType: SupportedCoinType) -> InitialSyncSetting {
        InitialSyncSetting(coinType: supportedCoinType.coinType, syncMode: supportedCoinType.defaultSyncMode)
    }

}

extension InitialSyncSettingsManager: IInitialSyncSettingsManager {

    var allSettings: [(setting: InitialSyncSetting, coin: Coin, changeable: Bool)] {
        let coins = coinKit.coins

        return supportedCoinTypes.compactMap { supportedCoinType in
            guard let coinTypeCoin = (coins.first { $0.type == supportedCoinType.coinType }) else {
                return nil
            }

            guard let setting = setting(coinType: supportedCoinType.coinType, accountOrigin: .restored) else {
                return nil
            }

            return (setting: setting, coin: coinTypeCoin, supportedCoinType.changeable)
        }
    }

    func save(setting: InitialSyncSetting) {
        storage.save(initialSyncSetting: setting)

        let walletsForUpdate = walletManager.activeWallets.filter { $0.coin.type == setting.coinType && $0.account.origin == .restored }

        if !walletsForUpdate.isEmpty {
            adapterManager.refreshAdapters(wallets: walletsForUpdate)
        }
    }

    func setting(coinType: CoinType, accountOrigin: AccountOrigin) -> InitialSyncSetting? {
        guard let supportedCoinType = supportedCoinTypes.first(where: { $0.coinType == coinType }) else {
            return nil
        }

        guard accountOrigin != .created else {
            return InitialSyncSetting(coinType: coinType, syncMode: .new)
        }

        guard supportedCoinType.changeable else {
            return defaultSetting(supportedCoinType: supportedCoinType)
        }

        let storedSetting = storage.initialSyncSetting(coinType: coinType)

        return storedSetting ?? defaultSetting(supportedCoinType: supportedCoinType)
    }

}

extension InitialSyncSettingsManager {

    private struct SupportedCoinType {
        let coinType: CoinType
        let defaultSyncMode: SyncMode
        let changeable: Bool
    }

}
