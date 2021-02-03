struct MarketDiscoveryModule {

    static func viewController(marketViewModel: MarketViewModel) -> MarketDiscoveryViewController {
        let categoriesProvider = MarketCategoriesProvider()
        let service = MarketDiscoveryService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, categoriesProvider: categoriesProvider)

        let viewModel = MarketDiscoveryViewModel(service: service)
        return MarketDiscoveryViewController(marketViewModel: marketViewModel, viewModel: viewModel)
    }

}
