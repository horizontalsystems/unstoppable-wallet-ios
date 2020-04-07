class DerivationSettingsInteractor {
    private let derivationSettingsManager: IDerivationSettingsManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider
    private let adapterManager: IAdapterManager

    init(derivationSettingsManager: IDerivationSettingsManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider, adapterManager: IAdapterManager) {
        self.derivationSettingsManager = derivationSettingsManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
        self.adapterManager = adapterManager
    }

}

extension DerivationSettingsInteractor: IDerivationSettingsInteractor {

    var allCoins: [Coin] {
        appConfigProvider.coins
    }

    func settings(coinType: CoinType) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coinType)
    }

    func walletsForUpdate(coinType: CoinType) -> [Wallet] {
        walletManager.wallets.filter { $0.coin.type == coinType }
    }

    func save(settings: [DerivationSetting]) {
        derivationSettingsManager.save(settings: settings)
    }

    func update(wallets: [Wallet]) {
        adapterManager.refreshAdapters(for: wallets)
    }

}
