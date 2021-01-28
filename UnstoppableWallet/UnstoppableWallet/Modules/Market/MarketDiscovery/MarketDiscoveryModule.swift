import Foundation

struct MarketDiscoveryModule {

    static func viewController() -> MarketDiscoveryViewController {
        let categoriesProvider = MarketCategoriesProvider()
        let service = MarketDiscoveryService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, categoriesProvider: categoriesProvider)

        let viewModel = MarketDiscoveryViewModel(service: service)
        return MarketDiscoveryViewController(viewModel: viewModel)
    }

}
