import ThemeKit
import UIKit

enum MarketTopModule {
    static func viewController(marketTop: MarketModule.MarketTop = .top100, sortingField: MarketModule.SortingField = .highestCap, marketField: MarketModule.MarketField = .price) -> UIViewController {
        let service = MarketTopService(
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            marketTop: marketTop,
            sortingField: sortingField,
            marketField: marketField
        )
        let watchlistToggleService = MarketWatchlistToggleService(
            coinUidService: service,
            favoritesManager: App.shared.favoritesManager,
            statPage: .topCoins
        )

        let decorator = MarketListMarketFieldDecorator(service: service, statPage: .topCoins)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketTopViewController(listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}
