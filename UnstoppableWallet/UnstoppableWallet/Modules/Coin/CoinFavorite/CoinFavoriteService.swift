import RxSwift
import RxCocoa

class CoinFavoriteService {
    private let manager: FavoritesManager
    private let coinUid: String
    private let disposeBag = DisposeBag()

    private let isFavoriteRelay = PublishRelay<Bool>()
    private(set) var isFavorite: Bool = false {
        didSet {
            if oldValue != isFavorite {
                isFavoriteRelay.accept(isFavorite)
            }
        }
    }

    init(manager: FavoritesManager, coinUid: String) {
        self.manager = manager
        self.coinUid = coinUid

        subscribe(disposeBag, manager.coinUidsUpdatedObservable) { [weak self] in self?.sync() }

        sync()
    }

    private func sync() {
        isFavorite = manager.isFavorite(coinUid: coinUid)
    }

}

extension CoinFavoriteService {

    var isFavoriteObservable: Observable<Bool> {
        isFavoriteRelay.asObservable()
    }

    func favorite() {
        manager.add(coinUid: coinUid)
    }

    func unfavorite() {
        manager.remove(coinUid: coinUid)
    }

}
