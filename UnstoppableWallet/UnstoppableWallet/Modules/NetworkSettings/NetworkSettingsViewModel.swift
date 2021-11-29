import RxSwift
import RxRelay
import RxCocoa

class NetworkSettingsViewModel {
    private let service: NetworkSettingsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let openEvmNetworkRelay = PublishRelay<(EvmNetworkModule.Blockchain, Account)>()

    init(service: NetworkSettingsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [NetworkSettingsService.Item]) {
        let viewItems = items.map { item in
            ViewItem(
                    iconName: iconName(blockchain: item.blockchain),
                    title: title(blockchain: item.blockchain),
                    value: item.value
            )
        }

        viewItemsRelay.accept(viewItems)
    }

    private func iconName(blockchain: NetworkSettingsService.Blockchain) -> String {
        switch blockchain {
        case .ethereum: return "ethereum_24"
        case .binanceSmartChain: return "binance_smart_chain_24"
        }
    }

    private func title(blockchain: NetworkSettingsService.Blockchain) -> String {
        switch blockchain {
        case .ethereum: return "Ethereum"
        case .binanceSmartChain: return "BSC"
        }
    }

}

extension NetworkSettingsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var openEvmNetworkSignal: Signal<(EvmNetworkModule.Blockchain, Account)> {
        openEvmNetworkRelay.asSignal()
    }

    func onSelect(index: Int) {
        let blockchain = service.items[index].blockchain

        switch blockchain {
        case .ethereum: openEvmNetworkRelay.accept((.ethereum, service.account))
        case .binanceSmartChain: openEvmNetworkRelay.accept((.binanceSmartChain, service.account))
        }
    }

}

extension NetworkSettingsViewModel {

    struct ViewItem {
        let iconName: String
        let title: String
        let value: String
    }

}
