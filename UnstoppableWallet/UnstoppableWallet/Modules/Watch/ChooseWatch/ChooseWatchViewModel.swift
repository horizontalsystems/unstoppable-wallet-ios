import Foundation
import MarketKit
import RxSwift
import RxRelay
import RxCocoa

protocol IChooseWatchService {
    var items: [WatchModule.Item] { get }
    func watch(enabledUids: [String])
}

class ChooseWatchViewModel {
    private var disposeBag = DisposeBag()
    private let service: IChooseWatchService
    private let watchRelay = PublishRelay<Void>()
    private let watchEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var enabledBlockchainUids = [String]()
    private let viewItems: [CoinToggleViewModel.ViewItem]
    private let watchType: WatchModule.WatchType

    init(service: IChooseWatchService, watchType: WatchModule.WatchType) {
        self.service = service
        self.watchType = watchType

        viewItems = service.items.map { item in
            switch item {
            case let .coin(token):
                return CoinToggleViewModel.ViewItem(
                    uid: token.type.id,
                    imageUrl: token.coin.imageUrl,
                    placeholderImageName: "placeholder_circle_32",
                    title: token.coin.code,
                    subtitle: token.coin.name,
                    badge: token.badge,
                    state: .toggleVisible(enabled: false, hasSettings: false, hasInfo: false)
                )

            case let .blockchain(blockchain):
                return CoinToggleViewModel.ViewItem(
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
        switch watchType {
        case .evmAddress: return "watch_address.choose_blockchain".localized
        case .publicKey: return "watch_address.choose_coin".localized
        case .tronAddress: return ""
        }
    }

    var watchSignal: Signal<Void> {
        watchRelay.asSignal()
    }

    var watchEnabledDriver: Driver<Bool> {
        watchEnabledRelay.asDriver()
    }

    func onTapWatch() {
        service.watch(enabledUids: enabledBlockchainUids)
        watchRelay.accept(())
    }

}

extension ChooseWatchViewModel: ICoinToggleViewModel {

    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> {
        Driver.just(viewItems)
    }

    func onEnable(uid: String) {
        if enabledBlockchainUids.isEmpty {
            watchEnabledRelay.accept(true)
        }

        enabledBlockchainUids.append(uid)
    }

    func onDisable(uid: String) {
        if let index = enabledBlockchainUids.firstIndex(of: uid) {
            enabledBlockchainUids.remove(at: index)

            if enabledBlockchainUids.isEmpty {
                watchEnabledRelay.accept(false)
            }
        }
    }

    func onTapSettings(uid: String) { }
    func onTapInfo(uid: String) { }
    func onUpdate(filter: String) {}

}
