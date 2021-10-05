import CurrencyKit

struct MarketWatchlistModule {

    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                favoritesManager: App.shared.favoritesManager
        )
        let viewModel = MarketWatchlistViewModel(service: service)
        return MarketWatchlistViewController(viewModel: viewModel)
    }

}
