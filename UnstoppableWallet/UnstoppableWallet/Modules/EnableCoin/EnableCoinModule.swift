struct EnableCoinModule {

    static func module(isRestore: Bool) -> (EnableCoinService, EnableCoinView) {
        let coinTokensService = CoinTokensService()
        let coinTokensViewModel = CoinTokensViewModel(service: coinTokensService)
        let coinTokensView = CoinTokensView(viewModel: coinTokensViewModel)

        let coinSettingsService = CoinSettingsService(isRestore: isRestore)
        let coinSettingsViewModel = CoinSettingsViewModel(service: coinSettingsService)
        let coinSettingsView = CoinSettingsView(viewModel: coinSettingsViewModel)

        let service = EnableCoinService(
                coinTokensService: coinTokensService,
                coinSettingsService: coinSettingsService
        )

        let view = EnableCoinView(
                coinTokensView: coinTokensView,
                coinSettingsView: coinSettingsView
        )

        return (service, view)
    }

}
