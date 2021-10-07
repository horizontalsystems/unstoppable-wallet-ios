import UIKit
import ThemeKit

struct MarketTopModule {

    static func viewController() -> UIViewController {
        let service = MarketTopService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let viewModel = MarketTopViewModel(service: service)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, marketFieldDataSource: headerViewModel)

        let viewController = MarketTopViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
