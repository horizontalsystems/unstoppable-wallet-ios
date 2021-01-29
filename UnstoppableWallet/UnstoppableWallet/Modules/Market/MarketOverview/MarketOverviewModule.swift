import Foundation

struct MarketOverviewModule {

    static func viewController(marketViewModel: MarketViewModel) -> MarketOverviewViewController {
        let dataSource = MarketListDataSource(rateManager: App.shared.rateManager)
        let service = MarketListService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, dataSource: dataSource)
        let viewModel = MarketOverviewViewModel(service: service)

        return MarketOverviewViewController(marketViewModel: marketViewModel, viewModel: viewModel)
    }

}
