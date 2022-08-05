import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import ComponentKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let disposeBag = DisposeBag()

    private let addWalletStateRelay = BehaviorRelay<AddWalletState>(value: .hidden)
    private let favoriteRelay: BehaviorRelay<Bool>
    private let hudRelay = PublishRelay<HudHelper.BannerType>()

    init(service: CoinPageService) {
        self.service = service

        favoriteRelay = BehaviorRelay(value: service.favorite)

        subscribe(disposeBag, service.favoriteObservable) { [weak self] favorite in
            self?.favoriteRelay.accept(favorite)
            self?.hudRelay.accept(favorite ? .addedToWatchlist : .removedFromWatchlist)
        }

        subscribe(disposeBag, service.walletStateObservable) { [weak self] in self?.sync(walletState: $0) }

        sync(walletState: service.walletState)
    }

    private func sync(walletState: CoinPageService.WalletState) {
        switch walletState {
        case .noActiveAccount, .watchAccount, .unsupported:
            addWalletStateRelay.accept(.hidden)
        case .supported(let added):
            addWalletStateRelay.accept(.visible(added: added))

            if added {
                hudRelay.accept(.addedToWallet)
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

    var hudSignal: Signal<HudHelper.BannerType> {
        hudRelay.asSignal()
    }

    var title: String {
        service.fullCoin.coin.code
    }

    func onTapFavorite() {
        service.toggleFavorite()
    }

    func onTapAddWallet() {
        switch service.walletState {
        case .supported(let added):
            if added {
                hudRelay.accept(.alreadyAddedToWallet)
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

}
