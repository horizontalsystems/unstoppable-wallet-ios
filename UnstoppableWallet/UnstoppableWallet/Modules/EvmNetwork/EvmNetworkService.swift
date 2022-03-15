import RxSwift
import RxRelay
import EthereumKit

class EvmNetworkService {
    let blockchain: EvmBlockchain
    private let evmSyncSourceManager: EvmSyncSourceManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(blockchain: EvmBlockchain, evmSyncSourceManager: EvmSyncSourceManager) {
        self.blockchain = blockchain
        self.evmSyncSourceManager = evmSyncSourceManager

        syncItems()
    }

    private func syncItems() {
        let currentNetwork = currentSyncSource

        items = evmSyncSourceManager.allSyncSources(blockchain: blockchain).map { syncSource in
            Item(
                    syncSource: syncSource,
                    selected: syncSource == currentNetwork
            )
        }
    }

    private var currentSyncSource: EvmSyncSource {
        evmSyncSourceManager.syncSource(blockchain: blockchain)
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

        evmSyncSourceManager.save(syncSource: syncSource, blockchain: blockchain)
    }

}

extension EvmNetworkService {

    struct Item {
        let syncSource: EvmSyncSource
        let selected: Bool
    }

}
