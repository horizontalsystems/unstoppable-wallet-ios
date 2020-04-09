class BlockchainSettingsStorage {
    let storage: IBlockchainSettingsRecordStorage

    let derivationKey = "derivation"
    let initialSyncKey = "initial_sync"

    init(storage: IBlockchainSettingsRecordStorage) {
        self.storage = storage
    }

}

extension BlockchainSettingsStorage: IBlockchainSettingsStorage {

    func derivationSetting(coinType: CoinType) -> DerivationSetting? {
        guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
            return nil
        }

        return storage.blockchainSettings(coinTypeKey: coinTypeKey, settingKey: derivationKey)
                .flatMap { record in
                    guard let derivation = MnemonicDerivation(rawValue: record.value) else {
                        return nil
                    }
                    return DerivationSetting(coinType: coinType, derivation: derivation)
                }
    }

    func save(derivationSettings: [DerivationSetting]) {
        let settingRecords: [BlockchainSettingRecord] = derivationSettings.compactMap { setting in
            guard let coinTypeKey = BlockchainSettingRecord.key(for: setting.coinType) else {
                return nil
            }
            return BlockchainSettingRecord(coinType: coinTypeKey, key: derivationKey, value: setting.derivation.rawValue)
        }

        storage.save(blockchainSettings: settingRecords)
    }

    func deleteDerivationSettings() {
        storage.deleteAll(settingKey: derivationKey)
    }

    func initialSyncSetting(coinType: CoinType) -> InitialSyncSetting? {
        guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
            return nil
        }

        return storage.blockchainSettings(coinTypeKey: coinTypeKey, settingKey: initialSyncKey)
                .flatMap { record in
                    guard let syncMode = SyncMode(rawValue: record.value) else {
                        return nil
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
