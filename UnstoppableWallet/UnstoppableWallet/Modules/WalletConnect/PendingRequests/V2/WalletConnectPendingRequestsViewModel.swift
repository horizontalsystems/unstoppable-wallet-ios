import RxSwift
import RxRelay
import RxCocoa

class WalletConnectPendingRequestsViewModel {
    private let service: WalletConnectPendingRequestsService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
    private let showPendingRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectPendingRequestsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in
            self?.sync(items: $0)
        }
        subscribe(disposeBag, service.showPendingRequestObservable) { [weak self] in
            self?.showPendingRequestRelay.accept($0)
        }

        sync(items: service.items)
    }

    private func sync(items: [WalletConnectPendingRequestsService.Item]) {
        let viewItems = items.map { item in
            SectionViewItem(
                    id: item.accountId,
                    selected: item.active,
                    title: item.accountName,
                    viewItems: item.requests.map { request in
                        ViewItem(
                                id: request.id,
                                title: request.method.title,
                                subtitle: service.blockchain(chainId: request.chainId) ?? "",
                                imageUrl: request.sessionImageUrl,
                                unsupported: request.method == .unsupported
                        )
                    }
            )
        }

        sectionViewItemsRelay.accept(viewItems)
    }

}

extension WalletConnectPendingRequestsViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var showPendingRequestSignal: Signal<WalletConnectRequest> {
        showPendingRequestRelay.asSignal()
    }

    func onSelect(requestId: Int) {
        service.select(requestId: requestId)
    }

    func onSelect(accountId: String) {
        service.select(accountId: accountId)
    }

    func onReject(id: Int) {
        service.onReject(id: id)
    }

}

extension WalletConnectPendingRequestsViewModel {

    struct ViewItem {
        let id: Int
        let title: String
        let subtitle: String
        let imageUrl: String?
        let unsupported: Bool
    }

    struct SectionViewItem {
        let id: String
        let selected: Bool
        let title: String
        let viewItems: [ViewItem]
    }

}

extension WalletConnectPendingRequestsService.RequestMethod {

    var title: String {
        switch self {
        case .ethSign: return "Sign Request"
        case .personalSign: return "Personal Sign Request"
        case .ethSignTypedData: return "Typed Sign Request"
        case .ethSendTransaction: return "Approve Transaction"
        case .unsupported: return "Unsupported"
        }
    }

}
