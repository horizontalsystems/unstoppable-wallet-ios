import Combine
import MarketKit

class CoinPageViewModelNew: ObservableObject {
    let fullCoin: FullCoin
    private let favoritesManager: FavoritesManager

    @Published var isFavorite: Bool {
        didSet {
            if isFavorite {
                favoritesManager.add(coinUid: fullCoin.coin.uid)
            } else {
                favoritesManager.remove(coinUid: fullCoin.coin.uid)
            }
        }
    }

    init(fullCoin: FullCoin, favoritesManager: FavoritesManager) {
        self.fullCoin = fullCoin
        self.favoritesManager = favoritesManager

        isFavorite = favoritesManager.isFavorite(coinUid: fullCoin.coin.uid)
    }
}
