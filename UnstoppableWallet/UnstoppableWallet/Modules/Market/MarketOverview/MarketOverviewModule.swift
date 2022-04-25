struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {

        let globalService = MarketOverviewGlobalService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let globalViewModel = MarketOverviewGlobalViewModel(service: globalService)
        let marketOverviewDataSource = MarketOverviewGlobalDataSource(viewModel: globalViewModel)

        let topCoinsService = MarketOverviewTopCoinsService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let topCoinsDecorator = MarketListMarketFieldDecorator(service: topCoinsService)
        let topCoinsViewModel = MarketOverviewTopCoinsViewModel(service: topCoinsService, decorator: topCoinsDecorator)
        let topCoinsDataSource = MarketOverviewTopCoinsDataSource(viewModel: topCoinsViewModel)

        let marketDiscoveryService = MarketDiscoveryService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, favoritesManager: App.shared.favoritesManager)
        let categoryViewModel = MarketOverviewCategoryViewModel(service: marketDiscoveryService)
        let categoryDataSource = MarketOverviewCategoryDataSource(viewModel: categoryViewModel)

        let nftCollectionsService = MarketOverviewNftCollectionsService(provider: App.shared.hsNftProvider, currencyKit: App.shared.currencyKit)
        let nftCollectionsDecorator = MarketListNftCollectionDecorator()
        let nftCollectionsViewModel = MarketOverviewNftCollectionsViewModel(service: nftCollectionsService, decorator: nftCollectionsDecorator)
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
