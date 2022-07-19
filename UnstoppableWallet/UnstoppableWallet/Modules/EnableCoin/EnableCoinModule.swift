struct EnableCoinModule {

    static func module() -> (EnableCoinService, EnableCoinView) {
        let coinTokensService = CoinTokensService()
        let coinTokensViewModel = CoinTokensViewModel(service: coinTokensService)
        let coinTokensView = CoinTokensView(viewModel: coinTokensViewModel)

        let restoreSettingsService = RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        let restoreSettingsViewModel = RestoreSettingsViewModel(service: restoreSettingsService)
        let restoreSettingsView = RestoreSettingsView(viewModel: restoreSettingsViewModel)

        let coinSettingsService = CoinSettingsService()
        let coinSettingsViewModel = CoinSettingsViewModel(service: coinSettingsService)
        let coinSettingsView = CoinSettingsView(viewModel: coinSettingsViewModel)

        let service = EnableCoinService(
                coinTokensService: coinTokensService,
                restoreSettingsService: restoreSettingsService,
                coinSettingsService: coinSettingsService
        )

        let view = EnableCoinView(
                coinTokensView: coinTokensView,
                restoreSettingsView: restoreSettingsView,
                coinSettingsView: coinSettingsView
        )

        return (service, view)
    }

}
