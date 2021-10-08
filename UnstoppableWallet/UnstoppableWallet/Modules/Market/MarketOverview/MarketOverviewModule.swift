struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewControllerNew {
        let service = MarketOverviewServiceNew(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let viewModel = MarketOverviewViewModelNew(service: service)

        let marketMetricsCell = MarketMetricsModule.cell()

        return MarketOverviewViewControllerNew(viewModel: viewModel, marketMetricsCell: marketMetricsCell)
    }

}
