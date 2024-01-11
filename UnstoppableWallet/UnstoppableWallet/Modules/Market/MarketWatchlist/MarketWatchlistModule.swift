import UIKit

enum MarketWatchlistModule {
    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            favoritesManager: App.shared.favoritesManager,
            appManager: App.shared.appManager,
            userDefaultsStorage: App.shared.userDefaultsStorage
        )
        let watchlistToggleService = MarketWatchlistToggleService(
            coinUidService: service,
            favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketWatchlistDecorator(service: service)
        let viewModel = MarketWatchlistViewModel(service: service)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: decorator)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)

        return MarketWatchlistViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)
    }
}
