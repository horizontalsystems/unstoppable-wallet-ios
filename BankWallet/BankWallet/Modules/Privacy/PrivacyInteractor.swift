class PrivacyInteractor {
    private let initialSyncSettingsManager: IInitialSyncSettingsManager

    init(initialSyncSettingsManager: IInitialSyncSettingsManager) {
        self.initialSyncSettingsManager = initialSyncSettingsManager
    }

}

extension PrivacyInteractor: IPrivacyInteractor {

    var syncSettings: [(setting: InitialSyncSetting, coins: [Coin])] {
        initialSyncSettingsManager.allSettings
    }

    func save(syncSetting: InitialSyncSetting) {
        initialSyncSettingsManager.save(setting: syncSetting)
    }

}
