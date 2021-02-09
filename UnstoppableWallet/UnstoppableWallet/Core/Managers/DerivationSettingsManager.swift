class DerivationSettingsManager {
    private let supportedCoinTypes: [(coinType: CoinType, defaultDerivation: MnemonicDerivation)] = [
        (.bitcoin, .bip49),
        (.litecoin, .bip49)
    ]

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let storage: IBlockchainSettingsStorage

    init (walletManager: IWalletManager, adapterManager: IAdapterManager, storage: IBlockchainSettingsStorage) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.storage = storage
    }

    private func defaultSetting(coinType: CoinType) -> DerivationSetting? {
        guard let derivation = supportedCoinTypes.first(where: { $0.coinType == coinType })?.defaultDerivation else {
            return nil
        }

        return DerivationSetting(coinType: coinType, derivation: derivation)
    }

}

extension DerivationSettingsManager: IDerivationSettingsManager {

    var allActiveSettings: [(setting: DerivationSetting, coinType: CoinType)] {
        let wallets = walletManager.wallets

        return supportedCoinTypes.compactMap { (coinType, _) in
            guard wallets.contains(where: { $0.coin.type == coinType }) else {
                return nil
            }

            guard let setting = setting(coinType: coinType) else {
                return nil
            }

            return (setting: setting, coinType: coinType)
        }
    }

    func setting(coinType: CoinType) -> DerivationSetting? {
        let storedSetting = storage.derivationSetting(coinType: coinType)
        return storedSetting ?? defaultSetting(coinType: coinType)
    }

    func save(setting: DerivationSetting) {
        storage.save(derivationSetting: setting)

        let walletsForUpdate = walletManager.wallets.filter { $0.coin.type == setting.coinType }

        if !walletsForUpdate.isEmpty {
            adapterManager.refreshAdapters(wallets: walletsForUpdate)
        }
    }

    func resetStandardSettings() {
        storage.deleteDerivationSettings()
    }

}
