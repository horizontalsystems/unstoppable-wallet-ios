protocol IBlockchainSettingsManager {
    var settableCoins: [Coin] { get }

    func save(settings: [BlockchainSetting])

    func settingsForCreate(coinType: CoinType) -> BlockchainSetting?
    func settings(coinType: CoinType) -> BlockchainSetting?
    var allSettings: [BlockchainSetting] { get }
}

class BlockchainSettingsManager: IBlockchainSettingsManager {
    private let appConfigProvider: IAppConfigProvider
    private let storage: IBlockchainSettingsStorage

    var settableCoins: [Coin] {
        appConfigProvider.defaultSettings.compactMap { setting in
            appConfigProvider.coins.first { $0.type == setting.coinType }
        }
    }

    init (appConfigProvider: IAppConfigProvider, storage: IBlockchainSettingsStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage
    }

    func save(settings: [BlockchainSetting]) {
        storage.save(settings: settings)
    }

    func settingsForCreate(coinType: CoinType) -> BlockchainSetting? {
        var setting = appConfigProvider.defaultSettings.first { $0.coinType == coinType }
        setting?.syncMode = .new
        return setting
    }

    func settings(coinType: CoinType) -> BlockchainSetting? {
        storage.blockchainSettings(coinType: coinType) ?? appConfigProvider.defaultSettings.first { $0.coinType == coinType }
    }

    var allSettings: [BlockchainSetting] {
        settableCoins.compactMap { coin in
            settings(coinType: coin.type)
        }
    }

}
