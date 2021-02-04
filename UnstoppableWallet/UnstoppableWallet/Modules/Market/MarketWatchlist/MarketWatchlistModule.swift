import CurrencyKit

struct MarketWatchlistModule {

    static func viewController() -> MarketWatchlistViewController {
        let service = MarketWatchlistService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, favoritesManager: App.shared.favoritesManager)

        let viewModel = MarketWatchlistViewModel(service: service)
        return MarketWatchlistViewController(viewModel: viewModel)
    }

}
