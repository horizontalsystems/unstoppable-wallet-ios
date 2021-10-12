class MarketWatchlistToggleService {
    private let listService: IMarketListService
    private let favoritesManager: FavoritesManager

    init(listService: IMarketListService, favoritesManager: FavoritesManager) {
        self.listService = listService
        self.favoritesManager = favoritesManager
    }

    private func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _) = listService.state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketWatchlistToggleService {

    func isFavorite(index: Int) -> Bool {
        guard let coinUid = coinUid(index: index) else {
            return false
        }

        return favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            return
        }

        favoritesManager.add(coinUid: coinUid)
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            return
        }

        favoritesManager.remove(coinUid: coinUid)
    }

}
