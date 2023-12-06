import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class ChooseWatchViewModel {
    private var disposeBag = DisposeBag()
    private let service: ChooseWatchService
    private let watchRelay = PublishRelay<Void>()
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var enabledUids = [String]()
    private let viewItems: [CoinToggleViewModel.ViewItem]

    init(service: ChooseWatchService) {
        self.service = service

        switch service.items {
        case let .coins(tokens):
            viewItems = tokens.map { token in
                CoinToggleViewModel.ViewItem(
                    uid: token.tokenQuery.id,
                    imageUrl: token.coin.imageUrl,
                    placeholderImageName: "placeholder_circle_32",
                    title: token.coin.code,
                    subtitle: token.coin.name,
                    badge: token.badge,
                    state: .toggleVisible(enabled: false, hasSettings: false, hasInfo: false)
                )
            }
        case let .blockchains(blockchains):
            viewItems = blockchains.map { blockchain in
                CoinToggleViewModel.ViewItem(
                    uid: blockchain.uid,
                    imageUrl: blockchain.type.imageUrl,
                    placeholderImageName: blockchain.type.placeholderImageName(tokenProtocol: .native),
                    title: blockchain.name,
                    subtitle: blockchain.type.description,
                    badge: nil,
                    state: .toggleVisible(enabled: false, hasSettings: false, hasInfo: false)
                )
            }
        }
    }
}

extension ChooseWatchViewModel {
    var title: String {
        switch service.items {
        case .blockchains: return "watch_address.choose_blockchain".localized
        case .coins: return "watch_address.choose_coin".localized
        }
    }

    var watchSignal: Signal<Void> {
        watchRelay.asSignal()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    func onTapWatch() {
        service.watch(enabledUids: enabledUids)
        watchRelay.accept(())
    }
}

extension ChooseWatchViewModel: ICoinToggleViewModel {
    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        Driver.just(viewItems)
    }

    func onEnable(uid: String) {
        if enabledUids.isEmpty {
            watchEnabledRelay.accept(true)
        }

        enabledUids.append(uid)
    }

    func onDisable(uid: String) {
        if let index = enabledUids.firstIndex(of: uid) {
            enabledUids.remove(at: index)

            if enabledUids.isEmpty {
                watchEnabledRelay.accept(false)
            }
        }
    }

    func onTapSettings(uid _: String) {}
    func onTapInfo(uid _: String) {}
    func onUpdate(filter _: String) {}
}
