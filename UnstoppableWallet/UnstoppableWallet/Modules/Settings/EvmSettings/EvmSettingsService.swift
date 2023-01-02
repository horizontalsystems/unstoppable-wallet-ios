import RxSwift
import RxRelay
import MarketKit

class EvmSettingsService {
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncItems() }

        syncItems()
    }

    private func syncItems() {
        let items: [Item] = evmBlockchainManager.allBlockchains.map { blockchain in
            let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
            return Item(blockchain: blockchain, syncSource: syncSource)
        }

        self.items = items.sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }

}

extension EvmSettingsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

}

extension EvmSettingsService {

    struct Item {
        let blockchain: Blockchain
        let syncSource: EvmSyncSource
    }

}
