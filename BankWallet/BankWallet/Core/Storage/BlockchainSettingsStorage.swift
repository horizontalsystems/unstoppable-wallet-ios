class BlockchainSettingsStorage {
    let storage: IBlockchainSettingsRecordStorage

    init(storage: IBlockchainSettingsRecordStorage) {
        self.storage = storage
    }

}

extension BlockchainSettingsStorage: IBlockchainSettingsStorage {

    func blockchainSettings(coinType: CoinType) -> BlockchainSetting? {
        guard let coinTypeKey = BlockchainSetting.key(for: coinType) else {
            return nil
        }

        return storage.blockchainSettings(coinTypeKey: coinTypeKey).map { record in
            BlockchainSetting(coinType: record.coinType, derivation: record.derivation, syncMode: record.syncMode)
        }
    }

    func save(settings: [BlockchainSetting]) {
        let settingRecords: [BlockchainSettingRecord] = settings.compactMap { setting in
            guard let coinType = setting.coinType, let coinTypeKey = BlockchainSetting.key(for: coinType) else {
                return nil
            }
            return BlockchainSettingRecord(coinType: coinTypeKey, derivation: setting.derivation?.rawValue, syncMode: setting.syncMode?.rawValue)
        }

        storage.save(blockchainSettings: settingRecords)
    }

}
