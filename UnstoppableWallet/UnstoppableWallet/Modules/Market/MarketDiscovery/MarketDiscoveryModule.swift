struct MarketDiscoveryModule {

    static func viewController(marketViewModel: MarketViewModel) -> MarketDiscoveryViewController {
        let service = MarketDiscoveryService(rateManager: App.shared.rateManager)
        let listService = MarketListService(currencyKit: App.shared.currencyKit, appManager: App.shared.appManager, fetcher: service)

        let viewModel = MarketDiscoveryViewModel(service: service)
        let listViewModel = MarketListViewModel(service: listService)

        return MarketDiscoveryViewController(marketViewModel: marketViewModel, listViewModel: listViewModel, viewModel: viewModel)
    }

}
