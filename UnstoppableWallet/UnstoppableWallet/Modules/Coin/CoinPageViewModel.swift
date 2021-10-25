import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let disposeBag = DisposeBag()
    let viewItem: ViewItem

    private let addWalletStateRelay = BehaviorRelay<AddWalletState>(value: .hidden)
    private let favoriteRelay: BehaviorRelay<Bool>
    private let successHudRelay = PublishRelay<String>()
    private let attentionHudRelay = PublishRelay<String>()

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
            self?.successHudRelay.accept(favorite ? "coin_page.favorited".localized : "coin_page.unfavorited".localized)
        }

        subscribe(disposeBag, service.walletStateObservable) { [weak self] in self?.sync(walletState: $0) }

        sync(walletState: service.walletState)
    }

    private func sync(walletState: CoinPageService.WalletState) {
        switch walletState {
        case .noActiveAccount, .unsupported:
            addWalletStateRelay.accept(.hidden)
        case .supported(let added):
            addWalletStateRelay.accept(.visible(added: added))

            if added {
                successHudRelay.accept("coin_page.added_to_wallet".localized)
            }
        }
    }

}

extension CoinPageViewModel {

    var addWalletStateDriver: Driver<AddWalletState> {
        addWalletStateRelay.asDriver()
    }

    var favoriteDriver: Driver<Bool> {
        favoriteRelay.asDriver()
    }

    var successHudSignal: Signal<String> {
        successHudRelay.asSignal()
    }

    var attentionHudSignal: Signal<String> {
        attentionHudRelay.asSignal()
    }

    func onTapFavorite() {
        service.toggleFavorite()
    }

    func onTapAddWallet() {
        switch service.walletState {
        case .supported(let added):
            if added {
                attentionHudRelay.accept("coin_page.already_added_to_wallet".localized)
            } else {
                service.addWallet()
            }
        default:
            ()
        }
    }

}

extension CoinPageViewModel {

    enum AddWalletState {
        case hidden
        case visible(added: Bool)
    }

    struct ViewItem {
        let title: String
        let subtitle: String
        let marketCapRank: String?
        let imageUrl: String
        let imagePlaceholderName: String
    }

}
