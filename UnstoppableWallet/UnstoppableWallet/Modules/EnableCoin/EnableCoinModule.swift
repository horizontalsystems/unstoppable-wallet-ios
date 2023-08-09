struct EnableCoinModule {

    static func module() -> (EnableCoinService, EnableCoinView) {
        let coinTokensService = CoinTokensService()
        let coinTokensViewModel = CoinTokensViewModel(service: coinTokensService)
        let coinTokensView = CoinTokensView(viewModel: coinTokensViewModel)

        let restoreSettingsService = RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        let restoreSettingsViewModel = RestoreSettingsViewModel(service: restoreSettingsService)
        let restoreSettingsView = RestoreSettingsView(viewModel: restoreSettingsViewModel)

        let service = EnableCoinService(
                coinTokensService: coinTokensService,
                restoreSettingsService: restoreSettingsService
        )

        let view = EnableCoinView(
                coinTokensView: coinTokensView,
                restoreSettingsView: restoreSettingsView
        )

        return (service, view)
    }

}
