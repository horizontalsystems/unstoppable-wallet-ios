class InitialSyncSettingsManager {
    private let supportedCoinTypes: [(coinType: CoinType, defaultSyncMode: SyncMode)] = [
        (.bitcoin, .fast),
        (.bitcoinCash, .fast),
        (.dash, .fast),
        (.litecoin, .fast)
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

    private func defaultSetting(coinType: CoinType) -> InitialSyncSetting? {
        guard let syncMode = supportedCoinTypes.first(where: { $0.coinType == coinType })?.defaultSyncMode else {
            return nil
        }

        return InitialSyncSetting(coinType: coinType, syncMode: syncMode)
    }

}

extension InitialSyncSettingsManager: IInitialSyncSettingsManager {

    var allSettings: [(setting: InitialSyncSetting, coins: [Coin])] {
        let coins = appConfigProvider.coins

        return supportedCoinTypes.compactMap { (coinType, _) in
            let coinTypeCoins = coins.filter { $0.type == coinType }

            guard !coinTypeCoins.isEmpty else {
                return nil
            }

            guard let setting = setting(coinType: coinType) else {
                return nil
            }

            return (setting: setting, coins: coinTypeCoins)
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
        let storedSetting = storage.initialSyncSetting(coinType: coinType)

        return storedSetting ?? defaultSetting(coinType: coinType)
    }

}
