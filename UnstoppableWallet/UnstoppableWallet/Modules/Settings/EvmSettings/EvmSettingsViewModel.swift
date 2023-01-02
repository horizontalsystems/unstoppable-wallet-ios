import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class EvmSettingsViewModel {
    private let service: EvmSettingsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let openBlockchainRelay = PublishRelay<Blockchain>()

    init(service: EvmSettingsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [EvmSettingsService.Item]) {
        let viewItems = items.map { item -> ViewItem in
            return ViewItem(
                    iconUrl: item.blockchain.type.imageUrl,
                    name: item.blockchain.name,
                    value: item.syncSource.name
            )
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension EvmSettingsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var openBlockchainSignal: Signal<Blockchain> {
        openBlockchainRelay.asSignal()
    }

    func onTapBlockchain(index: Int) {
        let item = service.items[index]
        openBlockchainRelay.accept(item.blockchain)
    }

}

extension EvmSettingsViewModel {

    struct ViewItem {
        let iconUrl: String
        let name: String
        let value: String
    }

}
