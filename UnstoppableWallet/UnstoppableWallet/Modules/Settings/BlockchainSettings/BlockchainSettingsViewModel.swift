import BitcoinCore
import Combine
import MarketKit
import RxRelay
import RxSwift

class BlockchainSettingsViewModel: ObservableObject {
    private let btcBlockchainManager: BtcBlockchainManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let moneroNodeManager: MoneroNodeManager
    private let marketKit: MarketKit.Kit
    private let disposeBag = DisposeBag()

    @Published var evmItems: [EvmItem] = []
    @Published var btcItems: [BtcSyncModeItem] = []
    @Published var moneroItem: MoneroItem? = nil

    init(btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, moneroNodeManager: MoneroNodeManager, marketKit: MarketKit.Kit) {
        self.btcBlockchainManager = btcBlockchainManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.moneroNodeManager = moneroNodeManager
        self.marketKit = marketKit

        subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncEvmItems() }
        subscribe(disposeBag, moneroNodeManager.nodeObservable) { [weak self] _ in self?.syncMoneroNodeItems() }

        syncBtcItems()
        syncEvmItems()
        syncMoneroNodeItems()
    }

    private func syncBtcItems() {
        btcItems = btcBlockchainManager.allBlockchains
            .map { blockchain in
                let restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
                return BtcSyncModeItem(blockchain: blockchain, restoreMode: restoreMode)
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

    private func syncMoneroNodeItems() {
        guard let blockchain = try? marketKit.blockchain(uid: BlockchainType.monero.uid) else { return }
        let moneroNode = moneroNodeManager.node(blockchainType: .monero)
        moneroItem = MoneroItem(blockchain: blockchain, node: moneroNode)
    }
}

extension BlockchainSettingsViewModel {
    struct EvmItem {
        let blockchain: Blockchain
        let syncSource: EvmSyncSource
    }

    struct MoneroItem {
        let blockchain: Blockchain
        let node: MoneroNode
    }
}

struct BtcSyncModeItem {
    let blockchain: Blockchain
    let restoreMode: BtcRestoreMode

    var title: String {
        switch restoreMode {
        case .blockchair: return "Blockchair API"
        case .hybrid: return "sync_mode.hybrid".localized
        case .blockchain: return "sync_mode.from_blockchain".localized(blockchain.name)
        }
    }
}
