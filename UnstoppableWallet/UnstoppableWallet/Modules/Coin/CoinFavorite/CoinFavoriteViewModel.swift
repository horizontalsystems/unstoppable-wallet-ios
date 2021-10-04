import RxSwift
import RxRelay
import RxCocoa

class CoinFavoriteViewModel {
    private let service: CoinFavoriteService
    private let disposeBag = DisposeBag()

    private let favoriteRelay = BehaviorRelay<Bool>(value: false)
    private let favoriteHudRelay = PublishRelay<String>()

    init(service: CoinFavoriteService) {
        self.service = service

        subscribe(disposeBag, service.isFavoriteObservable) { [weak self] isFavorite in
            self?.sync(favorite: isFavorite)
            self?.syncHud(favorite: isFavorite)
        }

        sync(favorite: service.isFavorite)
    }

    private func sync(favorite: Bool) {
        favoriteRelay.accept(favorite)
    }

    private func syncHud(favorite: Bool) {
        favoriteHudRelay.accept(favorite ? "coin_page.favorited".localized : "coin_page.unfavorited".localized)
    }

}

extension CoinFavoriteViewModel {

    var favoriteDriver: Driver<Bool> {
        favoriteRelay.asDriver()
    }

    var favoriteHudSignal: Signal<String> {
        favoriteHudRelay.asSignal()
    }

    func favorite() {
        service.favorite()
    }

    func unfavorite() {
        service.unfavorite()
    }

}
