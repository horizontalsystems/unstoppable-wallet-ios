protocol IDerivationSettingsManager {
    func save(setting: DerivationSetting)
    func save(settings: [DerivationSetting])

    func defaultDerivationSetting(coinType: CoinType) throws -> DerivationSetting
    func derivationSetting(coinType: CoinType) throws -> DerivationSetting
}

enum DerivationSettingError: Error {
    case unsupportedCoinType
    case unsupportedMnemonicDerivation
}

class DerivationSettingsManager: IDerivationSettingsManager {
    private let storage: IBlockchainSettingsStorage

    init (storage: IBlockchainSettingsStorage) {
        self.storage = storage
    }

    func save(setting: DerivationSetting) {
        storage.save(derivationSettings: [setting])
    }

    func save(settings: [DerivationSetting]) {
        storage.save(derivationSettings: settings)
    }

    func defaultDerivationSetting(coinType: CoinType) throws -> DerivationSetting {
        switch coinType {
        case .bitcoin: return DerivationSetting(coinType: coinType, derivation: .bip49)
        case .litecoin: return DerivationSetting(coinType: coinType, derivation: .bip49)
        default: throw DerivationSettingError.unsupportedCoinType
        }
    }

    func derivationSetting(coinType: CoinType) throws -> DerivationSetting {
        let setting = try storage.derivationSetting(coinType: coinType)

        return try setting ?? defaultDerivationSetting(coinType: coinType)
    }

}
