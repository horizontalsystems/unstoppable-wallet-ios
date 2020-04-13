class PrivacyInteractor {
    private let initialSyncSettingsManager: IInitialSyncSettingsManager
    private let transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager
    private let ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager

    init(initialSyncSettingsManager: IInitialSyncSettingsManager, transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager, ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager) {
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.transactionDataSortTypeSettingManager = transactionDataSortTypeSettingManager
        self.ethereumRpcModeSettingsManager = ethereumRpcModeSettingsManager
    }

}

extension PrivacyInteractor: IPrivacyInteractor {

    var syncSettings: [(setting: InitialSyncSetting, coins: [Coin])] {
        initialSyncSettingsManager.allSettings
    }

    var sortMode: TransactionDataSortMode {
        transactionDataSortTypeSettingManager.setting
    }

    var ethereumConnection: EthereumRpcMode {
        ethereumRpcModeSettingsManager.rpcMode
    }

    func save(syncSetting: InitialSyncSetting) {
        initialSyncSettingsManager.save(setting: syncSetting)
    }

    func save(connectionSetting: EthereumRpcMode) {
        ethereumRpcModeSettingsManager.save(rpcMode: connectionSetting)
    }

    func save(sortSetting: TransactionDataSortMode) {
        transactionDataSortTypeSettingManager.save(setting: sortSetting)
    }

}
