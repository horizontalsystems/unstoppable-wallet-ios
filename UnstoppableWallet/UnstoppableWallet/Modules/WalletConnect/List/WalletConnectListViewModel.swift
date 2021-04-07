import RxSwift
import RxRelay
import RxCocoa

class WalletConnectListViewModel {
    private let service: WalletConnectListService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])

    init(service: WalletConnectListService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

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

    private func title(chain: WalletConnectListService.Chain) -> String {
        switch chain {
        case .ethereum: return "Ethereum"
        case .binanceSmartChain: return "Binance Smart Chain"
        }
    }

}

extension WalletConnectListViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
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
