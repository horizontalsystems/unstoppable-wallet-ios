import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift

class CoinPageService {
    let fullCoin: FullCoin
    private let watchlistManager: WatchlistManager
    private var cancellables = Set<AnyCancellable>()

    private let favoriteRelay = PublishRelay<Bool>()
    private(set) var favorite: Bool = false {
        didSet {
            if oldValue != favorite {
                favoriteRelay.accept(favorite)
            }
        }
    }

    init(fullCoin: FullCoin, watchlistManager: WatchlistManager) {
        self.fullCoin = fullCoin
        self.watchlistManager = watchlistManager

        watchlistManager.coinUidsPublisher
            .sink { [weak self] _ in self?.syncFavorite() }
            .store(in: &cancellables)

        syncFavorite()
    }

    private func syncFavorite() {
        favorite = watchlistManager.isWatched(coinUid: fullCoin.coin.uid)
    }
}

extension CoinPageService {
    var favoriteObservable: Observable<Bool> {
        favoriteRelay.asObservable()
    }

    func toggleFavorite() {
        let coinUid = fullCoin.coin.uid

        if favorite {
            watchlistManager.remove(coinUid: coinUid)
            stat(page: .coinPage, event: .addToWatchlist(coinUid: coinUid))
        } else {
            watchlistManager.add(coinUid: coinUid)
            stat(page: .coinPage, event: .removeFromWatchlist(coinUid: coinUid))
        }
    }
}
