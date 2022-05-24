struct MarketOverviewModule {

    static func viewController(presentDelegate: IPresentDelegate) -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)

        let globalService = MarketOverviewGlobalService(baseService: service)
        let globalViewModel = MarketOverviewGlobalViewModel(service: globalService)
        let marketOverviewDataSource = MarketOverviewGlobalDataSource(viewModel: globalViewModel, presentDelegate: presentDelegate)

        let topGainersService = MarketOverviewTopCoinsService(listType: .topGainers, baseService: service)
        let topGainersDecorator = MarketListMarketFieldDecorator(service: topGainersService)
        let topGainersViewModel = MarketOverviewTopCoinsViewModel(service: topGainersService, decorator: topGainersDecorator)
        let topGainersDataSource = MarketOverviewTopCoinsDataSource(viewModel: topGainersViewModel, presentDelegate: presentDelegate)

        let topLosersService = MarketOverviewTopCoinsService(listType: .topLosers, baseService: service)
        let topLosersDecorator = MarketListMarketFieldDecorator(service: topLosersService)
        let topLosersViewModel = MarketOverviewTopCoinsViewModel(service: topLosersService, decorator: topLosersDecorator)
        let topLosersDataSource = MarketOverviewTopCoinsDataSource(viewModel: topLosersViewModel, presentDelegate: presentDelegate)

        let categoryService = MarketOverviewCategoryService(baseService: service)
        let categoryViewModel = MarketOverviewCategoryViewModel(service: categoryService)
        let categoryDataSource = MarketOverviewCategoryDataSource(viewModel: categoryViewModel, presentDelegate: presentDelegate)

        let nftCollectionsService = MarketOverviewNftCollectionsService(baseService: service)
        let nftCollectionsDecorator = MarketListNftCollectionDecorator(service: nftCollectionsService)
        let nftCollectionsViewModel = MarketOverviewNftCollectionsViewModel(service: nftCollectionsService, decorator: nftCollectionsDecorator)
        let nftCollectionsDataSource = MarketOverviewNftCollectionsDataSource(viewModel: nftCollectionsViewModel, presentDelegate: presentDelegate)

        let topPlatformsService = MarketOverviewTopPlatformsService(baseService: service)
        let topPlatformsDecorator = MarketListTopPlatformDecorator(service: topPlatformsService)
        let topPlatformsViewModel = MarketOverviewTopPlatformsViewModel(service: topPlatformsService, decorator: topPlatformsDecorator)
        let topPlatformsDataSource = MarketOverviewTopPlatformsDataSource(viewModel: topPlatformsViewModel, presentDelegate: presentDelegate)

        let viewModel = MarketOverviewViewModel(service: service)

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
