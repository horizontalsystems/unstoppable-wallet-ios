class MarketWatchlistToggleService {
    private let coinUidService: IMarketListCoinUidService
    private let favoritesManager: FavoritesManager

    init(coinUidService: IMarketListCoinUidService, favoritesManager: FavoritesManager) {
        self.coinUidService = coinUidService
        self.favoritesManager = favoritesManager
    }

}

extension MarketWatchlistToggleService {

    func isFavorite(index: Int) -> Bool? {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            return nil
        }

        return favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            return
        }

        favoritesManager.add(coinUid: coinUid)
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUidService.coinUid(index: index) else {
            return
        }

        favoritesManager.remove(coinUid: coinUid)
    }

}
