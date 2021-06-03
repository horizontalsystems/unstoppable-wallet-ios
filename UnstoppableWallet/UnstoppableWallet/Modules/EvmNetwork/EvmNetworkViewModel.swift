import RxSwift
import RxRelay
import RxCocoa

class EvmNetworkViewModel {
    private let service: EvmNetworkService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
    private let finishRelay = PublishRelay<()>()

    init(service: EvmNetworkService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [EvmNetworkService.Item]) {
        let mainNetItems = items.filter { $0.mainNet }
        let testNetItems = items.filter { !$0.mainNet }

        let sectionViewItems: [SectionViewItem?] = [
            sectionViewItem(title: "MainNet", viewItems: mainNetItems.map { viewItem(item: $0) }),
            sectionViewItem(title: "TestNet", viewItems: testNetItems.map { viewItem(item: $0) })
        ]

        sectionViewItemsRelay.accept(sectionViewItems.compactMap { $0 })
    }

    private func sectionViewItem(title: String, viewItems: [ViewItem]) -> SectionViewItem? {
        guard !viewItems.isEmpty else {
            return nil
        }

        return SectionViewItem(title: title, viewItems: viewItems)
    }

    private func viewItem(item: EvmNetworkService.Item) -> ViewItem {
        ViewItem(
                id: item.network.id,
                name: item.network.name,
                url: item.network.syncSource.url.absoluteString,
                selected: item.selected
        )
    }

}

extension EvmNetworkViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var title: String {
        switch service.blockchain {
        case .ethereum: return "Ethereum"
        case .binanceSmartChain: return "Binance Smart Chain"
        }
    }

    func onSelectViewItem(id: String) {
        service.setCurrentNetwork(id: id)
        finishRelay.accept(())
    }

}

extension EvmNetworkViewModel {

    struct SectionViewItem {
        let title: String
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let id: String
        let name: String
        let url: String
        let selected: Bool
    }

}
