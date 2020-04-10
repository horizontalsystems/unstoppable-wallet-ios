class PrivacyInteractor {
    private let initialSyncSettingsManager: IInitialSyncSettingsManager
    private let transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager

    init(initialSyncSettingsManager: IInitialSyncSettingsManager, transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager) {
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.transactionDataSortTypeSettingManager = transactionDataSortTypeSettingManager
    }

}

extension PrivacyInteractor: IPrivacyInteractor {

    var syncSettings: [(setting: InitialSyncSetting, coins: [Coin])] {
        initialSyncSettingsManager.allSettings
    }

    var sortMode: TransactionDataSortMode {
        transactionDataSortTypeSettingManager.setting
    }

    func save(syncSetting: InitialSyncSetting) {
        initialSyncSettingsManager.save(setting: syncSetting)
    }

    func save(sortSetting: TransactionDataSortMode) {
        transactionDataSortTypeSettingManager.save(setting: sortSetting)
    }

}
