import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class MoneroNetworkViewModel {
    private let service: MoneroNetworkService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: State(defaultViewItems: [], customViewItems: []))
    private let finishRelay = PublishRelay<Void>()

    init(service: MoneroNetworkService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MoneroNetworkService.State) {
        let state = State(
            defaultViewItems: state.defaultItems.map { viewItem(item: $0) },
            customViewItems: state.customItems.map { viewItem(item: $0) }
        )

        stateRelay.accept(state)
    }

    private func viewItem(item: MoneroNetworkService.Item) -> ViewItem {
        ViewItem(
            name: item.node.name,
            url: item.node.node.url.absoluteString,
            selected: item.selected
        )
    }
}

extension MoneroNetworkViewModel {
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

extension MoneroNetworkViewModel {
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
