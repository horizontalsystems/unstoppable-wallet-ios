import Foundation
import MarketKit
import RxSwift
import RxRelay
import RxCocoa

class ChooseCoinViewModel {
    private var disposeBag = DisposeBag()
    private let service: ChooseCoinService
    private let watchRelay = PublishRelay<Void>()
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var enabledTokensUids = [String]()

    var viewItems = [CoinToggleViewModel.ViewItem]()

    init(service: ChooseCoinService) {
        self.service = service

        viewItems = service.items.map { item in
            let coin = item.token.coin

            return CoinToggleViewModel.ViewItem(
                uid: item.uid,
                imageUrl: coin.imageUrl,
                placeholderImageName: "placeholder_circle_32",
                title: coin.code,
                subtitle: coin.name,
                badge: item.token.blockchain.type.badge(coinSettings: item.coinSettings),
                state: .toggleVisible(enabled: false, hasSettings: false, hasInfo: false)
            )
        }
    }

}

extension ChooseCoinViewModel {

    var watchSignal: Signal<Void> {
        watchRelay.asSignal()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    func onTapWatch() {
        service.watch(enabledTokensUids: enabledTokensUids)
        watchRelay.accept(())
    }

}

extension ChooseCoinViewModel: ICoinToggleViewModel {

    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        Driver.just(viewItems)
    }

    func onEnable(uid: String) {
        if enabledTokensUids.isEmpty {
            watchEnabledRelay.accept(true)
        }

        enabledTokensUids.append(uid)
    }

    func onDisable(uid: String) {
        if let index = enabledTokensUids.firstIndex(of: uid) {
            enabledTokensUids.remove(at: index)

            if enabledTokensUids.isEmpty {
                watchEnabledRelay.accept(false)
            }
        }
    }

    func onTapSettings(uid: String) { }
    func onTapInfo(uid: String) { }
    func onUpdate(filter: String) {}

}
