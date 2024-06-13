import Combine
import ComponentKit
import MarketKit

class CoinPageViewModelNew: ObservableObject {
    let coin: Coin
    private let watchlistManager = App.shared.watchlistManager

    @Published var isFavorite: Bool {
        didSet {
            if isFavorite {
                watchlistManager.add(coinUid: coin.uid)
                HudHelper.instance.show(banner: .addedToWatchlist)
            } else {
                watchlistManager.remove(coinUid: coin.uid)
                HudHelper.instance.show(banner: .removedFromWatchlist)
            }
        }
    }

    init(coin: Coin) {
        self.coin = coin

        isFavorite = watchlistManager.isWatched(coinUid: coin.uid)
    }
}
