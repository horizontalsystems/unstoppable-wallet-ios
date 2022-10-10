import RxSwift
import RxRelay
import EvmKit
import MarketKit

class EvmNetworkService {
    let blockchain: Blockchain
    private let evmSyncSourceManager: EvmSyncSourceManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(blockchain: Blockchain, evmSyncSourceManager: EvmSyncSourceManager) {
        self.blockchain = blockchain
        self.evmSyncSourceManager = evmSyncSourceManager

        syncItems()
    }

    private func syncItems() {
        let currentNetwork = currentSyncSource

        items = evmSyncSourceManager.allSyncSources(blockchainType: blockchain.type).map { syncSource in
            Item(
                    syncSource: syncSource,
                    selected: syncSource == currentNetwork
            )
        }
    }

    private var currentSyncSource: EvmSyncSource {
        evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
    }

}

extension EvmNetworkService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func setCurrent(syncSource: EvmSyncSource) {
        guard currentSyncSource != syncSource else {
            return
        }

        evmSyncSourceManager.save(syncSource: syncSource, blockchainType: blockchain.type)
    }

}

extension EvmNetworkService {

    struct Item {
        let syncSource: EvmSyncSource
        let selected: Bool
    }

}
