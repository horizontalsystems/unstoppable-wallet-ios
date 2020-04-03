class BlockchainSettingsStorage {
    let storage: IBlockchainSettingsRecordStorage

    let derivationKey = "derivation"
    let initialSyncKey = "initial_sync"

    init(storage: IBlockchainSettingsRecordStorage) {
        self.storage = storage
    }

}

extension BlockchainSettingsStorage: IBlockchainSettingsStorage {

    func derivationSetting(coinType: CoinType) throws -> DerivationSetting? {
        guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
            throw DerivationSettingError.unsupportedCoinType
        }

        return try storage.blockchainSettings(coinTypeKey: coinTypeKey, settingKey: derivationKey).map { record in
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
            return BlockchainSettingRecord(coinType: coinTypeKey, key: derivationKey, value: setting.derivation.rawValue)
        }

        storage.save(blockchainSettings: settingRecords)
    }

    func initialSyncSetting(coinType: CoinType) throws -> InitialSyncSetting? {
        guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
            throw InitialSyncSettingError.unsupportedCoinType
        }

        return try storage.blockchainSettings(coinTypeKey: coinTypeKey, settingKey: initialSyncKey).map { record in
            guard let syncMode = SyncMode(rawValue: record.value) else {
                throw InitialSyncSettingError.unsupportedSyncMode
            }
            return InitialSyncSetting(coinType: coinType, syncMode: syncMode)
        }
    }

    func save(initialSyncSettings: [InitialSyncSetting]) {
        let settingRecords: [BlockchainSettingRecord] = initialSyncSettings.compactMap { setting in
            let coinType = setting.coinType
            guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
                return nil
            }
            return BlockchainSettingRecord(coinType: coinTypeKey, key: initialSyncKey, value: setting.syncMode.rawValue)
        }

        storage.save(blockchainSettings: settingRecords)
    }

}
