import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class BlockchainSettingsViewModel {
    private let service: BlockchainSettingsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(btcViewItems: [], evmViewItems: []))
    private let openBtcBlockchainRelay = PublishRelay<Blockchain>()
    private let openEvmBlockchainRelay = PublishRelay<Blockchain>()

    init(service: BlockchainSettingsService) {
        self.service = service

        subscribe(disposeBag, service.itemObservable) { [weak self] in self?.sync(item: $0) }

        sync(item: service.item)
    }

    private func sync(item: BlockchainSettingsService.Item) {
        let btcViewItems = item.btcItems.map { btcItem in
            BlockchainViewItem(
                    iconUrl: btcItem.blockchain.type.imageUrl,
                    name: btcItem.blockchain.name,
                    value: "\(btcItem.restoreMode.title), \(btcItem.transactionMode.title)"
            )
        }

        let evmViewItems = item.evmItems.map { evmItem in
            BlockchainViewItem(
                    iconUrl: evmItem.blockchain.type.imageUrl,
                    name: evmItem.blockchain.name,
                    value: evmItem.syncSource.name
            )
        }

        viewItemRelay.accept(ViewItem(btcViewItems: btcViewItems, evmViewItems: evmViewItems))
    }

}

extension BlockchainSettingsViewModel {

    var viewItemDriver: Driver<ViewItem> {
        viewItemRelay.asDriver()
    }

    var openBtcBlockchainSignal: Signal<Blockchain> {
        openBtcBlockchainRelay.asSignal()
    }

    var openEvmBlockchainSignal: Signal<Blockchain> {
        openEvmBlockchainRelay.asSignal()
    }

    func onTapBtc(index: Int) {
        openBtcBlockchainRelay.accept(service.item.btcItems[index].blockchain)
    }

    func onTapEvm(index: Int) {
        openEvmBlockchainRelay.accept(service.item.evmItems[index].blockchain)
    }

}

extension BlockchainSettingsViewModel {

    struct ViewItem {
        let btcViewItems: [BlockchainViewItem]
        let evmViewItems: [BlockchainViewItem]
    }

    struct BlockchainViewItem {
        let iconUrl: String
        let name: String
        let value: String
    }

}
