import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

protocol IMarketListWatchViewModel: IMarketListViewModel {
    func isFavorite(index: Int) -> Bool?
    func favorite(index: Int)
    func unfavorite(index: Int)
}

class MarketListWatchViewModel<Service: IMarketListService, Decorator: IMarketListDecorator>: MarketListViewModel<Service, Decorator> {
    private let watchlistToggleService: MarketWatchlistToggleService

    init(service: Service, watchlistToggleService: MarketWatchlistToggleService, decorator: Decorator) {
        self.watchlistToggleService = watchlistToggleService

        super.init(service: service, decorator: decorator)
    }

}

extension MarketListWatchViewModel: IMarketListWatchViewModel {

    func isFavorite(index: Int) -> Bool? {
        watchlistToggleService.isFavorite(index: index)
    }

    func favorite(index: Int) {
        watchlistToggleService.favorite(index: index)
    }

    func unfavorite(index: Int) {
        watchlistToggleService.unfavorite(index: index)
    }

}
