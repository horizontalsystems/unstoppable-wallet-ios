class RestoreCoinsInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let derivationSettingsManager: IDerivationSettingsManager

    init(appConfigProvider: IAppConfigProvider, derivationSettingsManager: IDerivationSettingsManager) {
        self.appConfigProvider = appConfigProvider
        self.derivationSettingsManager = derivationSettingsManager
    }

}

extension RestoreCoinsInteractor: IRestoreCoinsInteractor {

    var coins: [Coin] {
        appConfigProvider.coins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func settings(coinType: CoinType) -> DerivationSetting? {
        try? derivationSettingsManager.derivationSetting(coinType: coinType)
    }

}
