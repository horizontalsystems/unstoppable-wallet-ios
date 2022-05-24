import UIKit
import ThemeKit

struct MarketTopModule {

    static func viewController(marketTop: MarketModule.MarketTop = .top100, sortingField: MarketModule.SortingField = .highestCap, marketField: MarketModule.MarketField = .price) -> UIViewController {
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
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketTopViewController(listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
