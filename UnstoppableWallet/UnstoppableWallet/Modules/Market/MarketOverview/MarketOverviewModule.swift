import Foundation

struct MarketOverviewModule {

    static func viewController(marketViewModel: MarketViewModel) -> MarketOverviewViewController {
        let service = MarketOverviewService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let viewModel = MarketOverviewViewModel(service: service)

        return MarketOverviewViewController(marketViewModel: marketViewModel, viewModel: viewModel)
    }

}
