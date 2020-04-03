protocol IInitialSyncSettingsManager {
    func save(setting: InitialSyncSetting)
    func save(settings: [InitialSyncSetting])

    func defaultInitialSyncSetting(coinType: CoinType) throws -> InitialSyncSetting
    func initialSyncSetting(coinType: CoinType) throws -> InitialSyncSetting
}

enum InitialSyncSettingError: Error {
    case unsupportedCoinType
    case unsupportedSyncMode
}

class InitialSyncSettingsManager: IInitialSyncSettingsManager {
    private let storage: IBlockchainSettingsStorage

    init (storage: IBlockchainSettingsStorage) {
        self.storage = storage
    }

    func save(setting: InitialSyncSetting) {
        storage.save(initialSyncSettings: [setting])
    }

    func save(settings: [InitialSyncSetting]) {
        storage.save(initialSyncSettings: settings)
    }

    func defaultInitialSyncSetting(coinType: CoinType) throws -> InitialSyncSetting {
        switch coinType {
        case .bitcoin: return InitialSyncSetting(coinType: coinType, syncMode: .fast)
        case .bitcoinCash: return InitialSyncSetting(coinType: coinType, syncMode: .fast)
        case .dash: return InitialSyncSetting(coinType: coinType, syncMode: .fast)
        case .litecoin: return InitialSyncSetting(coinType: coinType, syncMode: .fast)
        default: throw InitialSyncSettingError.unsupportedCoinType
        }
    }

    func initialSyncSetting(coinType: CoinType) throws -> InitialSyncSetting {
        let setting = try storage.initialSyncSetting(coinType: coinType)

        return try setting ?? defaultInitialSyncSetting(coinType: coinType)
    }

}
