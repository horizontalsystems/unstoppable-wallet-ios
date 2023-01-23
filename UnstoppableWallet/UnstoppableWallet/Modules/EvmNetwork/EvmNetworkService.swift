import RxSwift
import RxRelay
import EvmKit
import MarketKit

class EvmNetworkService {
    let blockchain: Blockchain
    private let evmSyncSourceManager: EvmSyncSourceManager
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = State(defaultItems: [], customItems: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(blockchain: Blockchain, evmSyncSourceManager: EvmSyncSourceManager) {
        self.blockchain = blockchain
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, evmSyncSourceManager.syncSourcesUpdatedObservable) { [weak self] _ in self?.syncState() }

        syncState()
    }

    private var currentSyncSource: EvmSyncSource {
        evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
    }

    private func syncState() {
        state = State(
                defaultItems: items(syncSources: evmSyncSourceManager.defaultSyncSources(blockchainType: blockchain.type)),
                customItems: items(syncSources: evmSyncSourceManager.customSyncSources(blockchainType: blockchain.type))
        )
    }

    private func items(syncSources: [EvmSyncSource]) -> [Item] {
        let currentSyncSource = currentSyncSource

        return syncSources.map { syncSource in
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

        evmSyncSourceManager.saveCurrent(syncSource: syncSource, blockchainType: blockchain.type)

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

    func removeCustom(index: Int) {
        evmSyncSourceManager.delete(syncSource: state.customItems[index].syncSource, blockchainType: blockchain.type)
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
