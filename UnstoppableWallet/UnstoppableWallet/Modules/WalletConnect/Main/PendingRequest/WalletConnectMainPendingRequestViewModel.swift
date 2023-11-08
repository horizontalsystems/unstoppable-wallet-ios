import RxCocoa
import RxRelay
import RxSwift

class WalletConnectMainPendingRequestViewModel {
    static let unsupported = "Unsupported"
    private let service: WalletConnectMainPendingRequestService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let showPendingRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectMainPendingRequestService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in
            self?.sync(items: $0)
        }
        subscribe(disposeBag, service.showPendingRequestObservable) { [weak self] in
            self?.showPendingRequestRelay.accept($0)
        }

        sync(items: service.items)
    }

    private func sync(items: [WalletConnectMainPendingRequestService.Item]) {
        let viewItems = items.map { request in
            ViewItem(
                id: request.id,
                title: request.methodName ?? Self.unsupported,
                subtitle: service.blockchain(chainId: request.chainId) ?? "",
                imageUrl: request.sessionImageUrl,
                unsupported: request.methodName == nil
            )
        }

        viewItemsRelay.accept(viewItems)
    }
}

extension WalletConnectMainPendingRequestViewModel {
    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var showPendingRequestSignal: Signal<WalletConnectRequest> {
        showPendingRequestRelay.asSignal()
    }

    func onSelect(requestId: Int) {
        service.select(requestId: requestId)
    }

    func onReject(id: Int) {
        service.onReject(id: id)
    }
}

extension WalletConnectMainPendingRequestViewModel {
    struct ViewItem {
        let id: Int
        let title: String
        let subtitle: String
        let imageUrl: String?
        let unsupported: Bool
    }
}
