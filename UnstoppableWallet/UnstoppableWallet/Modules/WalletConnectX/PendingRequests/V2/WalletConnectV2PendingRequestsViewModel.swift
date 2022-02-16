import RxSwift
import RxRelay
import RxCocoa

class WalletConnectV2PendingRequestsViewModel {
    private let service: WalletConnectV2PendingRequestsService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
    private let showPendingRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectV2PendingRequestsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in
            self?.sync(items: $0)
        }
        subscribe(disposeBag, service.showPendingRequestObservable) { [weak self] in
            self?.showPendingRequestRelay.accept($0)
        }

        sync(items: service.items)
    }

    private func sync(items: [WalletConnectV2PendingRequestsService.Item]) {
        let viewItems = items.map { item in
            SectionViewItem(
                    id: item.accountId,
                    selected: item.active,
                    title: item.accountName,
                    viewItems: item.requests.map { request in
                        ViewItem(
                                id: request.id,
                                title: title(method: request.method),
                                subtitle: request.sessionName
                        )
                    }
            )
        }

        sectionViewItemsRelay.accept(viewItems)
    }

    private func title(method: String) -> String {
        switch method {
        case "personal_sign": return "Personal Sign Request"
        case "eth_signTypedData": return "Typed Sign Request"
        case "eth_sendTransaction": return "Approve Transaction"
        default: return "Unsupported"
        }

    }
}

extension WalletConnectV2PendingRequestsViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var showPendingRequestSignal: Signal<WalletConnectRequest> {
        showPendingRequestRelay.asSignal()
    }

    func onSelect(requestId: Int64) {
        service.select(requestId: requestId)
    }

    func onSelect(accountId: String) {
        service.select(accountId: accountId)
    }

}

extension WalletConnectV2PendingRequestsViewModel {

    struct ViewItem {
        let id: Int64
        let title: String
        let subtitle: String
    }

    struct SectionViewItem {
        let id: String
        let selected: Bool
        let title: String
        let viewItems: [ViewItem]
    }

}
