import RxSwift
import RxRelay
import RxCocoa

class WalletConnectListViewModel {
    private let service: WalletConnectListService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
    private let showLoadingRelay = PublishRelay<()>()
    private let showSuccessRelay = PublishRelay<String?>()

    init(service: WalletConnectListService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.sessionKillingObservable) { [weak self] in self?.sync(sessionKillingState: $0) }

        sync(items: service.items)
    }

    private func sync(items: [WalletConnectListService.Item]) {
        let sectionViewItems = items.map { item in
            SectionViewItem(
                    title: title(chain: item.chain),
                    viewItems: item.sessions.map { session in
                        ViewItem(
                                session: session,
                                title: session.peerMeta.name,
                                url: session.peerMeta.url,
                                imageUrl: session.peerMeta.icons.last
                        )
                    }
            )
        }

        sectionViewItemsRelay.accept(sectionViewItems)
    }

    private func sync(sessionKillingState: WalletConnectListService.SessionKillingState) {
        switch sessionKillingState {
        case .processing: showLoadingRelay.accept(())
        case .completed: showSuccessRelay.accept("alert.success_action".localized)
        case .removedOnly: showSuccessRelay.accept("alert.success_action".localized)     // app just remove peerId from database
        }
    }

    private func title(chain: WalletConnectListService.Chain) -> String {
        switch chain {
        case .ethereum, .ropsten, .rinkeby, .kovan, .goerli: return "Ethereum"
        case .binanceSmartChain: return "Binance Smart Chain"
        }
    }

}

extension WalletConnectListViewModel {

    var emptySessionList: Bool { service.sessionCount == 0 }

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var showLoadingSignal: Signal<()> {
        showLoadingRelay.asSignal()
    }

    var showSuccessSignal: Signal<String?> {
        showSuccessRelay.asSignal()
    }

    func kill(session: WalletConnectSession) {
        service.kill(session: session)
    }

}

extension WalletConnectListViewModel {

    struct SectionViewItem {
        let title: String
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let session: WalletConnectSession
        let title: String
        let url: String
        let imageUrl: String?
    }

}
