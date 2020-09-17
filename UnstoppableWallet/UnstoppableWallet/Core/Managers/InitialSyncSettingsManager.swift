class InitialSyncSettingsManager {
    private let supportedCoinTypes = [
        SupportedCoinType(coinType: .bitcoin, defaultSyncMode: .fast, changeable: true),
        SupportedCoinType(coinType: .bitcoinCash, defaultSyncMode: .fast, changeable: true),
        SupportedCoinType(coinType: .dash, defaultSyncMode: .fast, changeable: true),
        SupportedCoinType(coinType: .litecoin, defaultSyncMode: .fast, changeable: true),
    ]

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let appConfigProvider: IAppConfigProvider
    private let storage: IBlockchainSettingsStorage

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, appConfigProvider: IAppConfigProvider, storage: IBlockchainSettingsStorage) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.appConfigProvider = appConfigProvider
        self.storage = storage
    }

    private func defaultSetting(supportedCoinType: SupportedCoinType) -> InitialSyncSetting {
        InitialSyncSetting(coinType: supportedCoinType.coinType, syncMode: supportedCoinType.defaultSyncMode)
    }

}

extension InitialSyncSettingsManager: IInitialSyncSettingsManager {

    var allSettings: [(setting: InitialSyncSetting, coins: [Coin], changeable: Bool)] {
        let coins = appConfigProvider.defaultCoins

        return supportedCoinTypes.compactMap { supportedCoinType in
            let coinTypeCoins = coins.filter { $0.type == supportedCoinType.coinType }

            guard !coinTypeCoins.isEmpty else {
                return nil
            }

            guard let setting = setting(coinType: supportedCoinType.coinType) else {
                return nil
            }

            return (setting: setting, coins: coinTypeCoins, supportedCoinType.changeable)
        }
    }

    func save(setting: InitialSyncSetting) {
        storage.save(initialSyncSettings: [setting])

        let walletsForUpdate = walletManager.wallets.filter { $0.coin.type == setting.coinType && $0.account.origin == .restored }

        if !walletsForUpdate.isEmpty {
            adapterManager.refreshAdapters(wallets: walletsForUpdate)
        }
    }

    func setting(coinType: CoinType) -> InitialSyncSetting? {
        guard let supportedCoinType = supportedCoinTypes.first(where: { $0.coinType == coinType }) else {
            return nil
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
