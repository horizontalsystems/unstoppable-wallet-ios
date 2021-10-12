import UIKit

struct MarketWatchlistModule {

    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                favoritesManager: App.shared.favoritesManager
        )
        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketWatchlistViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: .price)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, listViewModel: listViewModel)

        return MarketWatchlistViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)
    }

}
