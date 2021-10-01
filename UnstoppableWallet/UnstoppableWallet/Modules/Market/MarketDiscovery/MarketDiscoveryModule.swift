import UIKit
import ThemeKit

struct MarketDiscoveryModule {

    static func viewController() -> UIViewController {
        let service = MarketDiscoveryService(marketKit: App.shared.marketKit)
        let viewModel = MarketDiscoveryViewModel(service: service)
        let viewController = MarketDiscoveryViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
