class BlockchainSettingsStorage {
    let storage: IBlockchainSettingsRecordStorage

    let derivationKey = "derivation"     //
    let initialSyncKey = "initial_sync"  //use these two only for standard wallet

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

    func save(derivationSetting: DerivationSetting) {
        guard let coinTypeKey = BlockchainSettingRecord.key(for: derivationSetting.coinType) else {
            return
        }

        storage.save(blockchainSetting: BlockchainSettingRecord(coinType: coinTypeKey, key: derivationKey, value: derivationSetting.derivation.rawValue))
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

    func save(initialSyncSetting: InitialSyncSetting) {
        let coinType = initialSyncSetting.coinType
        guard let coinTypeKey = BlockchainSettingRecord.key(for: coinType) else {
            return
        }

        storage.save(blockchainSetting: BlockchainSettingRecord(coinType: coinTypeKey, key: initialSyncKey, value: initialSyncSetting.syncMode.rawValue))
    }

}
