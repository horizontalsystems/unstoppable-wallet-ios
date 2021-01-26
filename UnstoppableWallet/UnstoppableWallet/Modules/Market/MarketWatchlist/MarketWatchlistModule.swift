import Foundation

struct MarketWatchlistModule {

    static func view() -> MarketWatchlistViewController {
        let dataSource = MarketWatchlistDataSource(rateManager: App.shared.rateManager, favoritesManager: App.shared.favoritesManager)
        let service = MarketListService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, dataSource: dataSource)

        let viewModel = MarketWatchlistViewModel(service: service)
        return MarketWatchlistViewController(viewModel: viewModel)
    }

}
