import MarketKit

struct CoinDetailsModule {

    static func viewController(fullCoin: FullCoin) -> CoinDetailsViewController {
        let service = CoinDetailsService(
                fullCoin: fullCoin,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                proFeaturesManager: App.shared.proFeaturesAuthorizationManager
        )
        let proFeaturesService = ProFeaturesYakAuthorizationService(manager: App.shared.proFeaturesAuthorizationManager, adapter: App.shared.proFeaturesAuthorizationAdapter)

        let viewModel = CoinDetailsViewModel(service: service)
        let proFeaturesViewModel = ProFeaturesYakAuthorizationViewModel(service: proFeaturesService)

        return CoinDetailsViewController(viewModel: viewModel, proFeaturesViewModel: proFeaturesViewModel)
    }

}
