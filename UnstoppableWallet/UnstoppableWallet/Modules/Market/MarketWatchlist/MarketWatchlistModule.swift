import UIKit

struct MarketWatchlistModule {

    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketWatchlistViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, marketField: .price)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, listViewModel: listViewModel)

        return MarketWatchlistViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)
    }

}
