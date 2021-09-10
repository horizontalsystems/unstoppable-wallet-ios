import ThemeKit
import UIKit

class MarketSearchModule {

    static func viewController() -> UIViewController {
        let service = MarketSearchService(marketKit: App.shared.marketKit)
        let viewModel = MarketSearchViewModel(service: service)

        return ThemeNavigationController(rootViewController: MarketSearchViewController(viewModel: viewModel))
    }

}
