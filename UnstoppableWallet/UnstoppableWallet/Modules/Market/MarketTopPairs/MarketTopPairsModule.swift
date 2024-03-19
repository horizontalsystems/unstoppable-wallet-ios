import ThemeKit
import UIKit

enum MarketTopPairsModule {
    static func viewController() -> UIViewController {
        let viewModel = MarketTopPairsViewModel(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager, appManager: App.shared.appManager)
        let decorator = MarketListMarketPairDecorator(service: viewModel)
        let listViewModel = MarketListViewModel(service: viewModel, decorator: decorator)
        let viewController = MarketTopPairsViewController(viewModel: viewModel, listViewModel: listViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}
