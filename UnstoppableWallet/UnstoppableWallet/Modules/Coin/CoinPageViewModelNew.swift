import Combine
import ComponentKit
import MarketKit

class CoinPageViewModelNew: ObservableObject {
    let fullCoin: FullCoin
    private let watchlistManager = App.shared.watchlistManager

    @Published var isFavorite: Bool {
        didSet {
            if isFavorite {
                watchlistManager.add(coinUid: fullCoin.coin.uid)
                HudHelper.instance.show(banner: .addedToWatchlist)
            } else {
                watchlistManager.remove(coinUid: fullCoin.coin.uid)
                HudHelper.instance.show(banner: .removedFromWatchlist)
            }
        }
    }

    init(fullCoin: FullCoin) {
        self.fullCoin = fullCoin

        isFavorite = watchlistManager.isWatched(coinUid: fullCoin.coin.uid)
    }
}
