import UIKit
import ThemeKit

struct MarketTopModule {

    static func viewController(marketTop: MarketModule.MarketTop = .top250, sortingField: MarketModule.SortingField = .highestCap, marketField: MarketModule.MarketField = .price) -> UIViewController {
        let service = MarketTopService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                marketTop: marketTop,
                sortingField: sortingField
        )
        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketTopViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: marketField)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, listViewModel: listViewModel)

        let viewController = MarketTopViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
