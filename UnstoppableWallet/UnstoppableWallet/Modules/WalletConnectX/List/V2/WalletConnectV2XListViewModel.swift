import Foundation
import RxSwift
import RxCocoa
import WalletConnect

class WalletConnectV2XListViewModel {
    private let service: WalletConnectXListService
    private let disposeBag = DisposeBag()

    private let showWalletConnectSessionRelay = PublishRelay<Session>()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let pendingRequestCountRelay = BehaviorRelay<Int>(value: 0)
    private let showLoadingRelay = PublishRelay<()>()
    private let showSuccessRelay = PublishRelay<String?>()

    init(service: WalletConnectXListService) {
        self.service = service

        subscribe(disposeBag, service.itemsV2Observable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.pendingRequestsV2Observable) { [weak self] in self?.sync(pendingRequests: $0) }
//        subscribe(disposeBag, service.sessionKillingObservable) { [weak self] in self?.sync(sessionKillingState: $0) }
        subscribe(disposeBag, service.showSessionV2Observable) { [weak self] in self?.show(session: $0) }

        sync(items: service.itemsV2)
        sync(pendingRequests: service.pendingRequestsV2)
    }

    private func sync(items: [WalletConnectXListService.Item]) {
        let viewItems = items.map {
            ViewItem(
                id: $0.id,
                title: $0.appName,
                description: $0.chains.map { $0.title }.joined(separator: ", "),
                imageUrl: $0.appIcons.last
            )
        }

        viewItemsRelay.accept(viewItems)
    }

    private func sync(pendingRequests: [Request]) {
        pendingRequestCountRelay.accept(pendingRequests.count)
    }

    private func show(session: Session) {
        showWalletConnectSessionRelay.accept(session)
    }

}

extension WalletConnectV2XListViewModel {

    //Connections section

    var showWalletConnectSessionSignal: Signal<Session> {
        showWalletConnectSessionRelay.asSignal()
    }

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var pendingRequestCountDriver: Driver<Int> {
        pendingRequestCountRelay.asDriver()
    }

    var showLoadingSignal: Signal<()> {
        showLoadingRelay.asSignal()
    }

    var showSuccessSignal: Signal<String?> {
        showSuccessRelay.asSignal()
    }

    // Manage connections
    func showSession(id: Int) {
        service.showSession(id: id)
    }

    func kill(id: Int) {
        service.kill(id: id)
    }

}

extension WalletConnectV2XListViewModel {

    class ViewItem: WalletConnectXListViewModel.ViewItem {}

}
