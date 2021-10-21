import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let disposeBag = DisposeBag()
    let viewItem: ViewItem

    private let favoriteRelay: BehaviorRelay<Bool>
    private let favoriteHudRelay = PublishRelay<String>()

    init(service: CoinPageService) {
        self.service = service

        favoriteRelay = BehaviorRelay(value: service.favorite)

        let fullCoin = service.fullCoin
        viewItem = ViewItem(
                title: fullCoin.coin.code,
                subtitle: fullCoin.coin.name,
                marketCapRank: fullCoin.coin.marketCapRank.map { "#\($0)" },
                imageUrl: fullCoin.coin.imageUrl,
                imagePlaceholderName: fullCoin.placeholderImageName
        )

        subscribe(disposeBag, service.favoriteObservable) { [weak self] favorite in
            self?.favoriteRelay.accept(favorite)
            self?.favoriteHudRelay.accept(favorite ? "coin_page.favorited".localized : "coin_page.unfavorited".localized)
        }
    }

}

extension CoinPageViewModel {

    var favoriteDriver: Driver<Bool> {
        favoriteRelay.asDriver()
    }

    var favoriteHudSignal: Signal<String> {
        favoriteHudRelay.asSignal()
    }

    func toggleFavorite() {
        service.toggleFavorite()
    }

}

extension CoinPageViewModel {

    struct ViewItem {
        let title: String
        let subtitle: String
        let marketCapRank: String?
        let imageUrl: String
        let imagePlaceholderName: String
    }

}
