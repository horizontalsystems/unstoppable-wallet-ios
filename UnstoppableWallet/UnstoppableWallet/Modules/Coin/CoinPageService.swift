import Foundation
import MarketKit
import RxRelay
import RxSwift

class CoinPageService {
    let fullCoin: FullCoin
    private let favoritesManager: FavoritesManager
    private let disposeBag = DisposeBag()

    private let favoriteRelay = PublishRelay<Bool>()
    private(set) var favorite: Bool = false {
        didSet {
            if oldValue != favorite {
                favoriteRelay.accept(favorite)
            }
        }
    }

    init(fullCoin: FullCoin, favoritesManager: FavoritesManager) {
        self.fullCoin = fullCoin
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncFavorite() }

        syncFavorite()
    }

    private func syncFavorite() {
        favorite = favoritesManager.isFavorite(coinUid: fullCoin.coin.uid)
    }
}

extension CoinPageService {
    var favoriteObservable: Observable<Bool> {
        favoriteRelay.asObservable()
    }

    func toggleFavorite() {
        let coinUid = fullCoin.coin.uid

        if favorite {
            favoritesManager.remove(coinUid: coinUid)
            stat(page: .coinPage, event: .addToWatchlist(coinUid: coinUid))
        } else {
            favoritesManager.add(coinUid: coinUid)
            stat(page: .coinPage, event: .removeFromWatchlist(coinUid: coinUid))
        }
    }
}
