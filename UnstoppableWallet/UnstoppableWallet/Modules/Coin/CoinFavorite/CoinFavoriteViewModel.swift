import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class CoinFavoriteViewModel {
    private let service: CoinFavoriteService
    private let disposeBag = DisposeBag()

    private let favoriteRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinFavoriteService) {
        self.service = service

        subscribe(disposeBag, service.favoriteObservable) { [weak self] isFavorite in
            self?.sync(favorite: isFavorite)
        }

        sync(favorite: service.isFavorite)
    }

    private func sync(favorite: Bool) {
        favoriteRelay.accept(favorite)
    }

}

extension CoinFavoriteViewModel {

    var favoriteDriver: Driver<Bool> {
        favoriteRelay.asDriver()
    }

    func favorite() {
        service.favorite()
    }

    func unfavorite() {
        service.unfavorite()
    }

}
