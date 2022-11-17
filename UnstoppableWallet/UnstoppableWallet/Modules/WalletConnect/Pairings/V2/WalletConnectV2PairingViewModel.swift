import RxSwift
import RxRelay
import RxCocoa

class WalletConnectV2PairingViewModel {
    private let service: WalletConnectV2PairingService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let showDisconnectingRelay = PublishRelay<()>()
    private let showDisconnectedRelay = PublishRelay<Bool>()

    init(service: WalletConnectV2PairingService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.pairingKillingObservable) { [weak self] in self?.sync(pairingKillingState: $0) }

        sync(items: service.items)
    }

    private func sync(items: [WalletConnectV2PairingService.Item]) {
        let viewItems = items.map { item in
            ViewItem(topic: item.topic, title: item.appName, description: item.appUrl, imageUrl: item.appIcons.first)
        }

        viewItemRelay.accept(viewItems)
    }

    private func sync(pairingKillingState: WalletConnectV2PairingService.PairingKillingState) {
        switch pairingKillingState {
        case .processing: showDisconnectingRelay.accept(())
        case .completed: showDisconnectedRelay.accept(true)
        case .failed: showDisconnectedRelay.accept(false)
        }
    }

}

extension WalletConnectV2PairingViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemRelay.asDriver()
    }

    var showDisconnectingSignal: Signal<()> {
        showDisconnectingRelay.asSignal()
    }

    var showDisconnectedSignal: Signal<Bool> {
        showDisconnectedRelay.asSignal()
    }


    func onDisconnect(topic: String) {
        service.disconnect(topic: topic)
    }

    func onDisconnectAll() {
        service.disconnectAll()
    }

}

extension WalletConnectV2PairingViewModel {

    struct ViewItem {
        let topic: String
        let title: String
        let description: String?
        let imageUrl: String?
    }

}
