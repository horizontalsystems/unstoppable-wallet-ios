import Foundation

struct MarketDiscoveryModule {

    static func view() -> MarketDiscoveryViewController {
        let dataSource = MarketListDataSource(rateManager: App.shared.rateManager)
        let service = MarketListService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, dataSource: dataSource)

        let viewModel = MarketDiscoveryViewModel(service: service)
        return MarketDiscoveryViewController(viewModel: viewModel)
    }

}
