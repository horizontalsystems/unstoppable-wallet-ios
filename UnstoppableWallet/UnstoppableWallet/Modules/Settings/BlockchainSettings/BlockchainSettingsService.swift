import RxSwift
import RxRelay
import MarketKit

class BlockchainSettingsService {
    private let btcBlockchainManager: BtcBlockchainManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private let itemRelay = PublishRelay<Item>()
    private(set) var item: Item = Item(btcItems: [], evmItems: []) {
        didSet {
            itemRelay.accept(item)
        }
    }

    init(btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.btcBlockchainManager = btcBlockchainManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncItem() }
        subscribe(disposeBag, btcBlockchainManager.transactionSortModeUpdatedObservable) { [weak self] _ in self?.syncItem() }
        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncItem() }

        syncItem()
    }

    private func syncItem() {
        let btcItems: [BtcItem] = btcBlockchainManager.allBlockchains.map { blockchain in
            let restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
            let transactionMode = btcBlockchainManager.transactionSortMode(blockchainType: blockchain.type)
            return BtcItem(blockchain: blockchain, restoreMode: restoreMode, transactionMode: transactionMode)
        }

        let evmItems: [EvmItem] = evmBlockchainManager.allBlockchains.map { blockchain in
            let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
            return EvmItem(blockchain: blockchain, syncSource: syncSource)
        }

        item = Item(
                btcItems: btcItems.sorted { $0.blockchain.type.order < $1.blockchain.type.order },
                evmItems: evmItems.sorted { $0.blockchain.type.order < $1.blockchain.type.order }
        )
    }

}

extension BlockchainSettingsService {

    var itemObservable: Observable<Item> {
        itemRelay.asObservable()
    }

}

extension BlockchainSettingsService {

    struct Item {
        let btcItems: [BtcItem]
        let evmItems: [EvmItem]
    }

    struct BtcItem {
        let blockchain: Blockchain
        let restoreMode: BtcRestoreMode
        let transactionMode: TransactionDataSortMode
    }

    struct EvmItem {
        let blockchain: Blockchain
        let syncSource: EvmSyncSource
    }

}
