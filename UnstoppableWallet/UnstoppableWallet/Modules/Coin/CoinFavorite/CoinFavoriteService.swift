import RxSwift
import RxCocoa
import CoinKit

class CoinFavoriteService {
    private let service: FavoriteService
    private let coinType: CoinType
    private let disposeBag = DisposeBag()

    private let favoriteRelay = PublishRelay<Bool>()
    private(set) var isFavorite: Bool = false {
        didSet {
            favoriteRelay.accept(isFavorite)
        }
    }

    init(service: FavoriteService, coinType: CoinType) {
        self.service = service
        self.coinType = coinType

        subscribe(disposeBag, service.favoriteObservable(coinType: coinType)) { [weak self] in self?.sync(favorite: $0) }
    }

    private func sync(favorite: Bool) {
        isFavorite = favorite
    }

}

extension CoinFavoriteService {

    var favoriteObservable: Observable<Bool> {
        favoriteRelay.asObservable()
    }

    func favorite() {
        service.add(coinType: coinType)
    }

    func unfavorite() {
        service.remove(coinType: coinType)
    }

}
