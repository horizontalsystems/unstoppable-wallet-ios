import RxSwift

class MarketWatchlistToggleService {
    private let coinUidService: IMarketListCoinUidService
    private let favoritesManager: FavoritesManager
    private let statPage: StatPage

    private let statusSubject = PublishSubject<State>()

    init(coinUidService: IMarketListCoinUidService, favoritesManager: FavoritesManager, statPage: StatPage) {
        self.coinUidService = coinUidService
        self.favoritesManager = favoritesManager
        self.statPage = statPage
    }
}

extension MarketWatchlistToggleService {
    var statusObservable: Observable<State> {
        statusSubject.asObservable()
    }

    func isFavorite(index: Int) -> Bool? {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            return nil
        }

        return favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            statusSubject.onNext(.fail)
            return
        }

        favoritesManager.add(coinUid: coinUid)

        statusSubject.onNext(.favorite)

        stat(page: statPage, event: .addToWatchlist(coinUid: coinUid))
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            statusSubject.onNext(.fail)
            return
        }

        favoritesManager.remove(coinUid: coinUid)

        statusSubject.onNext(.unfavorite)

        stat(page: statPage, event: .removeFromWatchlist(coinUid: coinUid))
    }
}

extension MarketWatchlistToggleService {
    enum State {
        case favorite
        case unfavorite
        case fail
    }
}
