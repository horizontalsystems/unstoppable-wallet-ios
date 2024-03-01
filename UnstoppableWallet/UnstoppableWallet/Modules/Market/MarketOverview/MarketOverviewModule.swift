enum MarketOverviewModule {
    static func viewController(presentDelegate: IPresentDelegate) -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager, appManager: App.shared.appManager)

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

        let topPairsService = MarketOverviewTopPairsService(baseService: service)
        let topPairsDecorator = MarketListMarketPairDecorator(service: topPairsService)
        let topPairsViewModel = MarketOverviewTopPairsViewModel(service: topPairsService, decorator: topPairsDecorator)
        let topPairsDataSource = MarketOverviewTopPairsDataSource(viewModel: topPairsViewModel, presentDelegate: presentDelegate)

        let topPlatformsService = MarketOverviewTopPlatformsService(baseService: service)
        let topPlatformsDecorator = MarketListTopPlatformDecorator(service: topPlatformsService)
        let topPlatformsViewModel = MarketOverviewTopPlatformsViewModel(service: topPlatformsService, decorator: topPlatformsDecorator)
        let topPlatformsDataSource = MarketOverviewTopPlatformsDataSource(viewModel: topPlatformsViewModel, presentDelegate: presentDelegate)

        let categoryService = MarketOverviewCategoryService(listType: .topGainers, baseService: service)
        let categoryViewModel = MarketOverviewCategoryViewModel(service: categoryService)
        let categoryDataSource = MarketOverviewCategoryDataSource(viewModel: categoryViewModel, presentDelegate: presentDelegate)

        let viewModel = MarketOverviewViewModel(service: service)

        return MarketOverviewViewController(viewModel: viewModel, dataSources: [
            marketOverviewDataSource,
            topGainersDataSource,
            topLosersDataSource,
            topPairsDataSource,
            topPlatformsDataSource,
            categoryDataSource,
        ])
    }
}
