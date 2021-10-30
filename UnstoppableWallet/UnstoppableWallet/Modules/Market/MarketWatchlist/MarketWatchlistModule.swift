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

        let decorator = MarketListMarketFieldDecorator(service: service, marketField: .price)
        let viewModel = MarketWatchlistViewModel(service: service)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)

        return MarketWatchlistViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)
    }

}
