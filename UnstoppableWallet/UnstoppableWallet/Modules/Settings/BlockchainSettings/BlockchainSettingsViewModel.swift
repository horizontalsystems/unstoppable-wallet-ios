import Combine
import MarketKit
import RxRelay
import RxSwift
import BitcoinCore

class BlockchainSettingsViewModel: ObservableObject {
    private let btcBlockchainManager: BtcBlockchainManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    @Published var evmItems: [EvmItem] = []
    @Published var btcItems: [BtcSyncModeItem] = []

    init(btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.btcBlockchainManager = btcBlockchainManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncEvmItems() }

        syncBtcItems()
        syncEvmItems()
    }

    private func syncBtcItems() {
        btcItems = btcBlockchainManager.allBlockchains
            .map { blockchain in
                let restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
                let syncMode = btcBlockchainManager.apiSyncMode(blockchainType: blockchain.type)
                return BtcSyncModeItem(blockchain: blockchain, restoreMode: restoreMode, syncMode: syncMode)
            }
            .sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }

    private func syncEvmItems() {
        evmItems = evmBlockchainManager.allBlockchains
            .map { blockchain in
                let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
                return EvmItem(blockchain: blockchain, syncSource: syncSource)
            }
            .sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }
}

extension BlockchainSettingsViewModel {
    struct EvmItem {
        let blockchain: Blockchain
        let syncSource: EvmSyncSource
    }
}

struct BtcSyncModeItem {
    let blockchain: Blockchain
    let restoreMode: BtcRestoreMode
    let syncMode: BitcoinCore.SyncMode

    var title: String {
        switch (restoreMode, syncMode) {
            case (.api, .api): return "API"
            case (.api, .blockchair): return "Blockchair API"
            default: return "sync_mode.from_blockchain".localized(blockchain.name)
        }
    }
}
