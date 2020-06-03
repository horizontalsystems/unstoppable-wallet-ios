class RestoreCoinsInteractor {
    private let coinManager: ICoinManager
    private let derivationSettingsManager: IDerivationSettingsManager
    private let restoreManager: IRestoreManager

    init(coinManager: ICoinManager, derivationSettingsManager: IDerivationSettingsManager, restoreManager: IRestoreManager) {
        self.coinManager = coinManager
        self.derivationSettingsManager = derivationSettingsManager
        self.restoreManager = restoreManager
    }

}

extension RestoreCoinsInteractor: IRestoreCoinsInteractor {

    var coins: [Coin] {
        coinManager.coins
    }

    var featuredCoins: [Coin] {
        coinManager.featuredCoins
    }

    func derivationSetting(coinType: CoinType) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coinType)
    }

    func save(derivationSetting: DerivationSetting) {
        derivationSettingsManager.save(setting: derivationSetting)
    }

    func save(accountType: AccountType, coins: [Coin]) {
        restoreManager.createAccount(accountType: accountType, coins: coins)
    }

}
