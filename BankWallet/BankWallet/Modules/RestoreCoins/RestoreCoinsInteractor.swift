class RestoreCoinsInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let derivationSettingsManager: IDerivationSettingsManager
    private let restoreManager: IRestoreManager

    init(appConfigProvider: IAppConfigProvider, derivationSettingsManager: IDerivationSettingsManager, restoreManager: IRestoreManager) {
        self.appConfigProvider = appConfigProvider
        self.derivationSettingsManager = derivationSettingsManager
        self.restoreManager = restoreManager
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

    func save(accountType: AccountType, coins: [Coin]) {
        restoreManager.createAccount(accountType: accountType, coins: coins)
    }

}
