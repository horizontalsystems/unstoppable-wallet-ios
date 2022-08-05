import Foundation
import RxSwift
import RxCocoa

class WalletConnectV1ListViewModel {
    private let service: WalletConnectListService
    private let disposeBag = DisposeBag()

    private let showWalletConnectSessionRelay = PublishRelay<WalletConnectSession>()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let showLoadingRelay = PublishRelay<()>()
    private let showSuccessRelay = PublishRelay<()>()

    init(service: WalletConnectListService) {
        self.service = service

        subscribe(disposeBag, service.itemsV1Observable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.sessionKillingObservable) { [weak self] in self?.sync(sessionKillingState: $0) }
        subscribe(disposeBag, service.showSessionV1Observable) { [weak self] in self?.show(session: $0) }

        sync(items: service.itemsV1)
    }

    private func sync(items: [WalletConnectListService.Item]) {
        let viewItems = items.map {
            ViewItem(
                id: $0.id,
                title: $0.appName,
                description: $0.blockchains.map { $0.shortName }.joined(separator: ", "),
                imageUrl: $0.appIcons.last
            )
        }

        viewItemsRelay.accept(viewItems)
    }

    private func sync(sessionKillingState: WalletConnectListService.SessionKillingState) {
        switch sessionKillingState {
        case .processing: showLoadingRelay.accept(())
        case .completed: showSuccessRelay.accept(())        // don't needed different text
        case .removedOnly: showSuccessRelay.accept(())      // app just remove peerId from database
        }
    }

    private func show(session: WalletConnectSession) {
        showWalletConnectSessionRelay.accept(session)
    }

}

extension WalletConnectV1ListViewModel {

    //Connections section

    var showWalletConnectSessionSignal: Signal<WalletConnectSession> {
        showWalletConnectSessionRelay.asSignal()
    }

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var showLoadingSignal: Signal<()> {
        showLoadingRelay.asSignal()
    }

    var showSuccessSignal: Signal<()> {
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

extension WalletConnectV1ListViewModel {

    class ViewItem: WalletConnectListViewModel.ViewItem {}

}
