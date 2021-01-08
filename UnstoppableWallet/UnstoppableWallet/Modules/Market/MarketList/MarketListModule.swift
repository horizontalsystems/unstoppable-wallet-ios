struct MarketListModule {

    static func topView() -> MarketListView {
        let dataSource = MarketTopDataSource(rateManager: App.shared.rateManager, factory: MarketDataSourceFactory())
        let service = MarketListService(currencyKit: App.shared.currencyKit, dataSource: dataSource)
        let viewModel = MarketListViewModel(service: service)

        return MarketListView(viewModel: viewModel)
    }

    static func defiView() -> MarketListView {
        let dataSource = MarketDefiDataSource(rateManager: App.shared.rateManager, factory: MarketDataSourceFactory())
        let service = MarketListService(currencyKit: App.shared.currencyKit, dataSource: dataSource)
        let viewModel = MarketListViewModel(service: service)

        return MarketListView(viewModel: viewModel)
    }

}
