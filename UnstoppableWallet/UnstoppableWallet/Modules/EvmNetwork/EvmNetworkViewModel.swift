import EvmKit
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class EvmNetworkViewModel {
    private let service: EvmNetworkService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: State(defaultViewItems: [], customViewItems: []))
    private let finishRelay = PublishRelay<Void>()

    init(service: EvmNetworkService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: EvmNetworkService.State) {
        let state = State(
            defaultViewItems: state.defaultItems.map { viewItem(item: $0) },
            customViewItems: state.customItems.map { viewItem(item: $0) }
        )

        stateRelay.accept(state)
    }

    private func viewItem(item: EvmNetworkService.Item) -> ViewItem {
        ViewItem(
            name: item.syncSource.name,
            url: url(rpcSource: item.syncSource.rpcSource)?.absoluteString,
            selected: item.selected
        )
    }

    private func url(rpcSource: RpcSource) -> URL? {
        switch rpcSource {
        case let .http(urls, _): return urls.first
        case let .webSocket(url, _): return url
        }
    }
}

extension EvmNetworkViewModel {
    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    var title: String {
        service.blockchain.name
    }

    var iconUrl: String {
        service.blockchain.type.imageUrl
    }

    var blockchainType: BlockchainType {
        service.blockchain.type
    }

    func onSelectDefault(index: Int) {
        service.setDefault(index: index)
    }

    func onSelectCustom(index: Int) {
        service.setCustom(index: index)
    }

    func onRemoveCustom(index: Int) {
        service.removeCustom(index: index)
    }
}

extension EvmNetworkViewModel {
    struct State {
        let defaultViewItems: [ViewItem]
        let customViewItems: [ViewItem]
    }

    struct ViewItem {
        let name: String
        let url: String?
        let selected: Bool
    }
}
