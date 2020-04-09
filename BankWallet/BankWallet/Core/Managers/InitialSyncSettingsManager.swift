import RxSwift

class InitialSyncSettingsManager {
    private let supportedCoinTypes: [(coinType: CoinType, defaultSyncMode: SyncMode)] = [
        (.bitcoin, .fast),
        (.bitcoinCash, .fast),
        (.dash, .fast),
        (.litecoin, .fast)
    ]

    private let appConfigProvider: IAppConfigProvider
    private let storage: IBlockchainSettingsStorage

    private let subject = PublishSubject<CoinType>()

    init(appConfigProvider: IAppConfigProvider, storage: IBlockchainSettingsStorage) {
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

    var syncModeUpdatedObservable: Observable<CoinType> {
        subject.asObservable()
    }

    func save(setting: InitialSyncSetting) {
        storage.save(initialSyncSettings: [setting])
        subject.onNext(setting.coinType)
    }

    func setting(coinType: CoinType) -> InitialSyncSetting? {
        let storedSetting = storage.initialSyncSetting(coinType: coinType)

        return storedSetting ?? defaultSetting(coinType: coinType)
    }

}
