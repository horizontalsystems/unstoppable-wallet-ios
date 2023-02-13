import Foundation
import RxSwift
import RxRelay
import RxCocoa
import ComponentKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let disposeBag = DisposeBag()

    private let favoriteRelay: BehaviorRelay<Bool>
    private let hudRelay = PublishRelay<HudHelper.BannerType>()

    init(service: CoinPageService) {
        self.service = service

        favoriteRelay = BehaviorRelay(value: service.favorite)

        subscribe(disposeBag, service.favoriteObservable) { [weak self] favorite in
            self?.favoriteRelay.accept(favorite)
            self?.hudRelay.accept(favorite ? .addedToWatchlist : .removedFromWatchlist)
        }
    }

}

extension CoinPageViewModel {

    var favoriteDriver: Driver<Bool> {
        favoriteRelay.asDriver()
    }

    var hudSignal: Signal<HudHelper.BannerType> {
        hudRelay.asSignal()
    }

    var title: String {
        service.fullCoin.coin.code
    }

    func onTapFavorite() {
        service.toggleFavorite()
    }

}
