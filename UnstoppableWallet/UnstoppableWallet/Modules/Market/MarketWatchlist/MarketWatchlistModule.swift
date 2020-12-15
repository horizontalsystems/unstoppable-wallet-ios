import Foundation

struct MarketWatchlistModule {

    static func view(service: MarketWatchlistService) -> MarketWatchlistView {
        let viewModel = MarketWatchlistViewModel(service: service)

        return MarketWatchlistView(viewModel: viewModel)
    }

}
