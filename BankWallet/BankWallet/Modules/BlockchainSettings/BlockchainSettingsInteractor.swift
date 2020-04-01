class BlockchainSettingsInteractor {
    private let derivationSettingsManager: IDerivationSettingsManager
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider

    init(derivationSettingsManager: IDerivationSettingsManager, walletManager: IWalletManager, appConfigProvider: IAppConfigProvider) {
        self.derivationSettingsManager = derivationSettingsManager
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
    }

}

extension BlockchainSettingsInteractor: IBlockchainSettingsInteractor {

    var allCoins: [Coin] {
        appConfigProvider.coins
    }

    func settings(coinType: CoinType) -> DerivationSetting? {
        try? derivationSettingsManager.derivationSetting(coinType: coinType)
    }

    func walletsForUpdate(coinType: CoinType) -> [Wallet] {
        walletManager.wallets.filter { $0.coin.type == coinType }
    }

    func save(settings: [DerivationSetting]) {
        derivationSettingsManager.save(settings: settings)
    }

    func update(wallets: [Wallet]) {
        walletManager.save(wallets: wallets)
    }

}
