struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {
        let service = MarketOverviewTopCoinsService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)

        let decorator = MarketListMarketFieldDecorator(service: service)
        let topCoinsViewModel = MarketOverviewTopCoinsViewModel(service: service, decorator: decorator)
        let marketOverviewDataSource = MarketOverviewTopCoinsDataSource(viewModel: topCoinsViewModel)

        let marketDiscoveryService = MarketDiscoveryService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, favoritesManager: App.shared.favoritesManager)
        let marketCategoryViewModel = MarketOverviewCategoryViewModel(service: marketDiscoveryService)
        let marketCategoryDataSource = MarketOverviewCategoryDataSource(viewModel: marketCategoryViewModel)

        let viewModel = MarketOverviewViewModel(dataSources: [marketOverviewDataSource, marketCategoryDataSource])

        return MarketOverviewViewController(viewModel: viewModel)
    }

}
