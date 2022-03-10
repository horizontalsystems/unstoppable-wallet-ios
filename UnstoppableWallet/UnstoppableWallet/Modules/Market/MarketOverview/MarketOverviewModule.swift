struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)

        let decorator = MarketListMarketFieldDecorator(service: service)
        let topCoinsViewModel = MarketOverviewTopCoinsViewModel(service: service, decorator: decorator)
        let marketOverviewDataSource = MarketOverviewTopCoinsDataSource(viewModel: topCoinsViewModel)

        let viewModel = MarketOverviewViewModel(dataSources: [marketOverviewDataSource])

        return MarketOverviewViewController(viewModel: viewModel)
    }

}
