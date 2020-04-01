class BlockchainSettingsStorage {
    let storage: IBlockchainSettingsRecordStorage

    init(storage: IBlockchainSettingsRecordStorage) {
        self.storage = storage
    }

}

extension BlockchainSettingsStorage: IBlockchainSettingsStorage {

    func derivationSetting(coinType: CoinType) throws -> DerivationSetting? {
        guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
            throw DerivationSettingError.unsupportedCoinType
        }

        return try storage.blockchainSettings(coinTypeKey: coinTypeKey, settingKey: "derivation").map { record in
            guard let derivation = MnemonicDerivation(rawValue: record.value) else {
                throw DerivationSettingError.unsupportedMnemonicDerivation
            }
            return DerivationSetting(coinType: coinType, derivation: derivation)
        }
    }

    func save(derivationSettings: [DerivationSetting]) {
        let settingRecords: [BlockchainSettingRecord] = derivationSettings.compactMap { setting in
            let coinType = setting.coinType
            guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
                return nil
            }
            return BlockchainSettingRecord(coinType: coinTypeKey, key: "derivation", value: setting.derivation.rawValue)
        }

        storage.save(blockchainSettings: settingRecords)
    }

}
