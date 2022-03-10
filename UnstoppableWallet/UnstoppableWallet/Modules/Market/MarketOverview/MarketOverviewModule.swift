struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)

        let decorator = MarketListMarketFieldDecorator(service: service)
        let viewModel = MarketOverviewTopCoinsViewModel(service: service, decorator: decorator)

        let marketOverviewDataSource = MarketOverviewTopCoinsDataSource(viewModel: viewModel)

        return MarketOverviewViewController(dataSources: [marketOverviewDataSource])
    }

}
