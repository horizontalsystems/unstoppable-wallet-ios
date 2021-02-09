import CurrencyKit

struct MarketWatchlistModule {

    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(rateManager: App.shared.rateManager, favoritesManager: App.shared.favoritesManager)
        let listService = MarketListService(currencyKit: App.shared.currencyKit, fetcher: service)

        let listViewModel = MarketListViewModel(service: listService)
        return MarketWatchlistViewController(listViewModel: listViewModel)
    }

}
