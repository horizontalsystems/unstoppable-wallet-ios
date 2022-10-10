import Foundation
import RxSwift
import RxRelay
import RxCocoa
import EvmKit

class EvmNetworkViewModel {
    private let service: EvmNetworkService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let finishRelay = PublishRelay<()>()

    init(service: EvmNetworkService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [EvmNetworkService.Item]) {
        let viewItems = items.map { viewItem(item: $0) }
        viewItemsRelay.accept(viewItems)
    }

    private func viewItem(item: EvmNetworkService.Item) -> ViewItem {
        ViewItem(
                name: item.syncSource.name,
                url: item.syncSource.rpcSource.url?.absoluteString,
                selected: item.selected
        )
    }

}

extension EvmNetworkViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var title: String {
        service.blockchain.name
    }

    var iconUrl: String {
        service.blockchain.type.imageUrl
    }

    func onSelectViewItem(index: Int) {
        let item = service.items[index]
        service.setCurrent(syncSource: item.syncSource)
        finishRelay.accept(())
    }

}

extension EvmNetworkViewModel {

    struct ViewItem {
        let name: String
        let url: String?
        let selected: Bool
    }

}

extension RpcSource {

    var url: URL? {
        switch self {
        case .http(let urls, _): return urls.first
        case .webSocket(let url, _): return url
        }
    }

}
