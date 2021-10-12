struct MarketOverviewModule {

    static func viewController() -> MarketOverviewViewController {
        let service = MarketOverviewService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)
        let viewModel = MarketOverviewViewModel(service: service)

        let marketMetricsCell = MarketMetricsModule.cell()

        return MarketOverviewViewController(viewModel: viewModel, marketMetricsCell: marketMetricsCell)
    }

}
