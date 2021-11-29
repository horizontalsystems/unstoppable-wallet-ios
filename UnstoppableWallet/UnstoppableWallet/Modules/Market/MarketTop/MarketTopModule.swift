import UIKit
import ThemeKit

struct MarketTopModule {

    static func viewController(marketTop: MarketModule.MarketTop = .top250, sortingField: MarketModule.SortingField = .highestCap, marketField: MarketModule.MarketField = .price) -> UIViewController {
        let service = MarketTopService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                marketTop: marketTop,
                sortingField: sortingField,
                marketField: marketField
        )
        let watchlistToggleService = MarketWatchlistToggleService(
                coinUidService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListMarketFieldDecorator(service: service)
        let viewModel = MarketTopViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketTopViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
