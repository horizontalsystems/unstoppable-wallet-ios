class BlockchainSettingsStorage {
    private let storage: IBlockchainSettingsRecordStorage

    private let networkCoinTypeKey = "network_coin_type"
    private let derivationKey = "derivation"     //
    private let initialSyncKey = "initial_sync"  //use these two only for standard wallet

    init(storage: IBlockchainSettingsRecordStorage) {
        self.storage = storage
    }

}

extension BlockchainSettingsStorage: IBlockchainSettingsStorage {

    var bitcoinCashCoinType: BitcoinCashCoinType? {
        get {
            guard let coinTypeKey = BlockchainSettingRecord.key(for: .bitcoinCash) else {
                return nil
            }

            return storage.blockchainSettings(coinTypeKey: coinTypeKey, settingKey: networkCoinTypeKey)
                    .flatMap { record in
                        BitcoinCashCoinType(rawValue: record.value)
                    }
        }
        set {
            guard let newValue = newValue else {
                storage.deleteAll(settingKey: networkCoinTypeKey)
                return
            }

            guard let coinTypeKey = BlockchainSettingRecord.key(for: .bitcoinCash) else {
                return
            }

            storage.save(blockchainSetting: BlockchainSettingRecord(coinType: coinTypeKey, key: networkCoinTypeKey, value: newValue.rawValue))
        }
    }

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
