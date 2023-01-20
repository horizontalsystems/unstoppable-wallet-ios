import RxSwift
import RxRelay
import EvmKit
import MarketKit

class EvmNetworkService {
    let blockchain: Blockchain
    private let evmSyncSourceManager: EvmSyncSourceManager
    private var currentSyncSource: EvmSyncSource

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = State(defaultItems: [], customItems: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(blockchain: Blockchain, evmSyncSourceManager: EvmSyncSourceManager) {
        self.blockchain = blockchain
        self.evmSyncSourceManager = evmSyncSourceManager

        currentSyncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)

        syncState()
    }

    private func syncState() {
        state = State(
                defaultItems: items(syncSources: evmSyncSourceManager.defaultSyncSources(blockchainType: blockchain.type)),
                customItems: items(syncSources: evmSyncSourceManager.customSyncSources(blockchainType: blockchain.type))
        )
    }

    private func items(syncSources: [EvmSyncSource]) -> [Item] {
        syncSources.map { syncSource in
            Item(
                    syncSource: syncSource,
                    selected: syncSource == currentSyncSource
            )
        }
    }

    func setCurrent(syncSource: EvmSyncSource) {
        guard currentSyncSource != syncSource else {
            return
        }

        evmSyncSourceManager.save(syncSource: syncSource, blockchainType: blockchain.type)

        currentSyncSource = syncSource
        syncState()
    }

}

extension EvmNetworkService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func setDefault(index: Int) {
        setCurrent(syncSource: state.defaultItems[index].syncSource)
    }

    func setCustom(index: Int) {
        setCurrent(syncSource: state.customItems[index].syncSource)
    }

}

extension EvmNetworkService {

    struct State {
        let defaultItems: [Item]
        let customItems: [Item]
    }

    struct Item {
        let syncSource: EvmSyncSource
        let selected: Bool
    }

}
