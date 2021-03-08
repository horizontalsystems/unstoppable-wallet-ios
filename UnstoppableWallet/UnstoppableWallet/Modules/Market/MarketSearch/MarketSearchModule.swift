import ThemeKit
import UIKit

class MarketSearchModule {

    static func viewController() -> UIViewController {
        let service = MarketSearchService(rateManager: App.shared.rateManager)
        let viewModel = MarketSearchViewModel(service: service)

        return ThemeNavigationController(rootViewController: MarketSearchViewController(viewModel: viewModel))
    }

}
