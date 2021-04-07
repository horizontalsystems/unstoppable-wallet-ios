import CoinKit

class PrivacyInteractor {
    private let accountManager: IAccountManager
    private let initialSyncSettingsManager: IInitialSyncSettingsManager
    private let transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager
    private let ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager

    init(accountManager: IAccountManager, initialSyncSettingsManager: IInitialSyncSettingsManager, transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager, ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager) {
        self.accountManager = accountManager
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.transactionDataSortTypeSettingManager = transactionDataSortTypeSettingManager
        self.ethereumRpcModeSettingsManager = ethereumRpcModeSettingsManager
    }

}

extension PrivacyInteractor: IPrivacyInteractor {

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var syncSettings: [(setting: InitialSyncSetting, coin: Coin, changeable: Bool)] {
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
