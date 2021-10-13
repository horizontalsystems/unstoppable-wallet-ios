struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let viewModel = MarketOverviewViewModel(service: service)
        return MarketOverviewViewController(viewModel: viewModel)
    }

}
