struct MarketDiscoveryModule {

    static func viewController(marketViewModel: MarketViewModel) -> MarketDiscoveryViewController {
        let categoriesProvider = MarketCategoriesProvider()
        let service = MarketDiscoveryService(rateManager: App.shared.rateManager, categoriesProvider: categoriesProvider)
        let listService = MarketListService(currencyKit: App.shared.currencyKit, fetcher: service)

        let viewModel = MarketDiscoveryViewModel(service: service)
        let listViewModel = MarketListViewModel(service: listService)

        return MarketDiscoveryViewController(marketViewModel: marketViewModel, listViewModel: listViewModel, viewModel: viewModel)
    }

}
