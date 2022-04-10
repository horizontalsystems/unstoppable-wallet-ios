struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {

        let globalService = MarketOverviewGlobalService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let globalViewModel = MarketOverviewGlobalViewModel(service: globalService)
        let marketOverviewDataSource = MarketOverviewGlobalDataSource(viewModel: globalViewModel)

        let topCoinsService = MarketOverviewTopCoinsService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let decorator = MarketListMarketFieldDecorator(service: topCoinsService)
        let topCoinsViewModel = MarketOverviewTopCoinsViewModel(service: topCoinsService, decorator: decorator)
        let topCoinsDataSource = MarketOverviewTopCoinsDataSource(viewModel: topCoinsViewModel)

        let marketDiscoveryService = MarketDiscoveryService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, favoritesManager: App.shared.favoritesManager)
        let categoryViewModel = MarketOverviewCategoryViewModel(service: marketDiscoveryService)
        let categoryDataSource = MarketOverviewCategoryDataSource(viewModel: categoryViewModel)

        let nftCollectionsService = MarketOverviewNftCollectionsService(provider: App.shared.hsNftProvider, currencyKit: App.shared.currencyKit)
        let nftCollectionsViewModel = MarketOverviewNftCollectionsViewModel(service: nftCollectionsService)
        let nftCollectionsDataSource = MarketOverviewTopCoinsDataSource(viewModel: nftCollectionsViewModel)

        let viewModel = MarketOverviewViewModel(dataSources: [
            marketOverviewDataSource,
            topCoinsDataSource,
            categoryDataSource,
            nftCollectionsDataSource
        ])

        return MarketOverviewViewController(viewModel: viewModel)
    }

}
