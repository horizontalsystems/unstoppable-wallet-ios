struct MarketOverviewModule {

    static func viewController(presentDelegate: IPresentDelegate) -> MarketOverviewViewController {

        let globalService = MarketOverviewGlobalService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let globalViewModel = MarketOverviewGlobalViewModel(service: globalService)
        let marketOverviewDataSource = MarketOverviewGlobalDataSource(viewModel: globalViewModel, presentDelegate: presentDelegate)

        let topGainersService = MarketOverviewTopCoinsService(listType: .topGainers, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let topGainersDecorator = MarketListMarketFieldDecorator(service: topGainersService)
        let topGainersViewModel = MarketOverviewTopCoinsViewModel(service: topGainersService, decorator: topGainersDecorator)
        let topGainersDataSource = MarketOverviewTopCoinsDataSource(viewModel: topGainersViewModel, presentDelegate: presentDelegate)

        let topLosersService = MarketOverviewTopCoinsService(listType: .topLosers, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let topLosersDecorator = MarketListMarketFieldDecorator(service: topLosersService)
        let topLosersViewModel = MarketOverviewTopCoinsViewModel(service: topLosersService, decorator: topLosersDecorator)
        let topLosersDataSource = MarketOverviewTopCoinsDataSource(viewModel: topLosersViewModel, presentDelegate: presentDelegate)

        let marketDiscoveryService = MarketDiscoveryService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, favoritesManager: App.shared.favoritesManager)
        let categoryViewModel = MarketOverviewCategoryViewModel(service: marketDiscoveryService)
        let categoryDataSource = MarketOverviewCategoryDataSource(viewModel: categoryViewModel, presentDelegate: presentDelegate)

        let nftCollectionsService = MarketOverviewNftCollectionsService(provider: App.shared.hsNftProvider, currencyKit: App.shared.currencyKit)
        let nftCollectionsDecorator = MarketListNftCollectionDecorator()
        let nftCollectionsViewModel = MarketOverviewNftCollectionsViewModel(service: nftCollectionsService, decorator: nftCollectionsDecorator)
        let nftCollectionsDataSource = MarketOverviewNftCollectionsDataSource(viewModel: nftCollectionsViewModel, presentDelegate: presentDelegate)

        let topPlatformsService = MarketOverviewTopPlatformsService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let topPlatformsDecorator = MarketListTopPlatformDecorator(service: topPlatformsService)
        let topPlatformsViewModel = MarketOverviewTopPlatformsViewModel(service: topPlatformsService, decorator: topPlatformsDecorator)
        let topPlatformsDataSource = MarketOverviewTopPlatformsDataSource(viewModel: topPlatformsViewModel, presentDelegate: presentDelegate)

        let viewModel = MarketOverviewViewModel(viewModels: [
            globalViewModel,
            topGainersViewModel,
            topLosersViewModel,
            categoryViewModel,
            nftCollectionsViewModel,
            topPlatformsViewModel
        ])

        return MarketOverviewViewController(viewModel: viewModel, dataSources: [
            marketOverviewDataSource,
            topGainersDataSource,
            topLosersDataSource,
            categoryDataSource,
            nftCollectionsDataSource,
            topPlatformsDataSource
        ])
    }

}
