struct EnableCoinModule {

    static func module() -> (EnableCoinService, EnableCoinView) {
        let coinPlatformsService = CoinPlatformsService()
        let coinPlatformsViewModel = CoinPlatformsViewModel(service: coinPlatformsService)
        let coinPlatformsView = CoinPlatformsView(viewModel: coinPlatformsViewModel)

        let restoreSettingsService = RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        let restoreSettingsViewModel = RestoreSettingsViewModel(service: restoreSettingsService)
        let restoreSettingsView = RestoreSettingsView(viewModel: restoreSettingsViewModel)

        let coinSettingsService = CoinSettingsService()
        let coinSettingsViewModel = CoinSettingsViewModel(service: coinSettingsService)
        let coinSettingsView = CoinSettingsView(viewModel: coinSettingsViewModel)

        let service = EnableCoinService(
                coinPlatformsService: coinPlatformsService,
                restoreSettingsService: restoreSettingsService,
                coinSettingsService: coinSettingsService
        )

        let view = EnableCoinView(
                coinPlatformsView: coinPlatformsView,
                restoreSettingsView: restoreSettingsView,
                coinSettingsView: coinSettingsView
        )

        return (service, view)
    }

}
