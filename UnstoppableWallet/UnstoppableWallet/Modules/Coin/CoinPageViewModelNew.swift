import Combine
import MarketKit

class CoinPageViewModelNew: ObservableObject {
    let fullCoin: FullCoin
    private let watchlistManager: WatchlistManager

    @Published var isFavorite: Bool {
        didSet {
            if isFavorite {
                watchlistManager.add(coinUid: fullCoin.coin.uid)
            } else {
                watchlistManager.remove(coinUid: fullCoin.coin.uid)
            }
        }
    }

    init(fullCoin: FullCoin, watchlistManager: WatchlistManager) {
        self.fullCoin = fullCoin
        self.watchlistManager = watchlistManager

        isFavorite = watchlistManager.isWatched(coinUid: fullCoin.coin.uid)
    }
}
