import UIKit

struct MarketWatchlistModule {

    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                favoritesManager: App.shared.favoritesManager
        )

        let headerViewModel = MarketMultiSortHeaderViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service)

        return MarketWatchlistViewController(listViewModel: listViewModel, headerViewModel: headerViewModel)
    }

}
