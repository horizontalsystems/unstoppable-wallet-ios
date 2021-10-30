import UIKit

struct MarketDiscoveryModule {

    static func viewController() -> UIViewController {
        let service = MarketDiscoveryService(marketKit: App.shared.marketKit, favoritesManager: App.shared.favoritesManager)
        let viewModel = MarketDiscoveryViewModel(service: service)
        return MarketDiscoveryViewController(viewModel: viewModel)
    }

}
