import MarketKit

class PrivacyInteractor {
    private let accountManager: IAccountManager
    private let initialSyncSettingsManager: InitialSyncSettingsManager
    private let transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager

    init(accountManager: IAccountManager, initialSyncSettingsManager: InitialSyncSettingsManager, transactionDataSortTypeSettingManager: ITransactionDataSortModeSettingManager) {
        self.accountManager = accountManager
        self.initialSyncSettingsManager = initialSyncSettingsManager
        self.transactionDataSortTypeSettingManager = transactionDataSortTypeSettingManager
    }

}

extension PrivacyInteractor: IPrivacyInteractor {

    var activeAccount: Account? {
        accountManager.activeAccount
    }

    var syncSettings: [(setting: InitialSyncSetting, platformCoin: PlatformCoin, changeable: Bool)] {
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
