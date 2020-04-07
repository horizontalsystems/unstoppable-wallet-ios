class DerivationSettingsManager {
    private let supportedCoinTypes: [CoinType: MnemonicDerivation] = [
        .bitcoin: .bip49,
        .litecoin: .bip49,
    ]

    private let storage: IBlockchainSettingsStorage

    init (storage: IBlockchainSettingsStorage) {
        self.storage = storage
    }

    private func defaultSetting(coinType: CoinType) -> DerivationSetting? {
        guard let derivation = supportedCoinTypes[coinType] else {
            return nil
        }

        return DerivationSetting(coinType: coinType, derivation: derivation)
    }

}

extension DerivationSettingsManager: IDerivationSettingsManager {

    func setting(coinType: CoinType) -> DerivationSetting? {
        let storedSetting = storage.derivationSetting(coinType: coinType)
        return storedSetting ?? defaultSetting(coinType: coinType)
    }

    func save(settings: [DerivationSetting]) {
        storage.save(derivationSettings: settings)
    }

    func reset() {
        storage.deleteDerivationSettings()
    }

}
