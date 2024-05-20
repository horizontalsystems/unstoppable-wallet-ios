import RxSwift

class MarketWatchlistToggleService {
    private let coinUidService: IMarketListCoinUidService
    private let watchlistManager: WatchlistManager
    private let statPage: StatPage

    private let statusSubject = PublishSubject<State>()

    init(coinUidService: IMarketListCoinUidService, watchlistManager: WatchlistManager, statPage: StatPage) {
        self.coinUidService = coinUidService
        self.watchlistManager = watchlistManager
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

        return watchlistManager.isWatched(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            statusSubject.onNext(.fail)
            return
        }

        watchlistManager.add(coinUid: coinUid)

        statusSubject.onNext(.favorite)

        stat(page: statPage, event: .addToWatchlist(coinUid: coinUid))
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            statusSubject.onNext(.fail)
            return
        }

        watchlistManager.remove(coinUid: coinUid)

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
