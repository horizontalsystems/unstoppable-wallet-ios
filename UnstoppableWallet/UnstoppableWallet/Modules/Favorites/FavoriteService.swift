import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class FavoriteService {
    private var disposeBag = DisposeBag()

    private let favoritesManager: IFavoritesManager

    private let stateRelay = PublishRelay<[CoinType]>()
    private(set) var state: [CoinType] = [] {
        didSet {
            stateRelay.accept(state)
        }
    }

    var coinTypeRelays = [CoinType: BehaviorRelay<Bool>]()

    init(favoritesManager: IFavoritesManager) {
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.dataUpdatedObservable) { [weak self] in
            self?.syncFavorites()
        }

        syncFavorites()
    }

    private func syncFavorites() {
        let favorites = favoritesManager.all.map { $0.coinType }
        state = favorites

        coinTypeRelays.forEach { coinType, relay in
            let contains = favorites.contains(coinType)

            if contains != relay.value {
                relay.accept(contains)
            }
        }
    }

}

extension FavoriteService {

    func favoriteObservable(coinType: CoinType) -> Observable<Bool> {
        if let relay = coinTypeRelays[coinType] {
            return relay.asObservable()
        }

        let relay = BehaviorRelay<Bool>(value: favoritesManager.isFavorite(coinType: coinType))
        coinTypeRelays[coinType] = relay

        return relay.asObservable()
    }

    func add(coinType: CoinType) {
        favoritesManager.add(coinType: coinType)
    }

    func remove(coinType: CoinType) {
        favoritesManager.remove(coinType: coinType)
    }

}
