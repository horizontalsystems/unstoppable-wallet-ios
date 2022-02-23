import RxSwift
import RxRelay
import RxCocoa
import EthereumKit

class NetworkSettingsViewModel {
    private let service: NetworkSettingsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let openEvmNetworkRelay = PublishRelay<(EvmBlockchain, Account)>()

    init(service: NetworkSettingsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [NetworkSettingsService.Item]) {
        let viewItems = items.map { item in
            ViewItem(
                    iconName: item.blockchain.icon24,
                    title: item.blockchain.shortName,
                    value: item.syncSource.name
            )
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension NetworkSettingsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var openEvmNetworkSignal: Signal<(EvmBlockchain, Account)> {
        openEvmNetworkRelay.asSignal()
    }

    func onSelect(index: Int) {
        let blockchain = service.items[index].blockchain
        openEvmNetworkRelay.accept((blockchain, service.account))
    }

}

extension NetworkSettingsViewModel {

    struct ViewItem {
        let iconName: String
        let title: String
        let value: String
    }

}
