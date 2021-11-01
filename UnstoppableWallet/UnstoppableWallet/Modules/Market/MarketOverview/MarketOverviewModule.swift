struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)

        let decorator = MarketListMarketFieldDecorator(service: service)
        let viewModel = MarketOverviewViewModel(service: service, decorator: decorator)

        return MarketOverviewViewController(viewModel: viewModel)
    }

}
