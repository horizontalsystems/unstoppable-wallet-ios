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

    @Published var evmItems: [Item] = []
    @Published var btcItems: [Item] = []

    init(btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, moneroNodeManager: MoneroNodeManager, marketKit: MarketKit.Kit) {
        self.btcBlockchainManager = btcBlockchainManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.moneroNodeManager = moneroNodeManager
        self.marketKit = marketKit

        subscribe(MainScheduler.instance, disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(MainScheduler.instance, disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncEvmItems() }
        subscribe(MainScheduler.instance, disposeBag, moneroNodeManager.nodeObservable) { [weak self] _ in self?.syncBtcItems() }

        syncBtcItems()
        syncEvmItems()
    }

    private func syncBtcItems() {
        var items = btcBlockchainManager.allBlockchains
            .map { blockchain in
                let restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
                return Item(blockchain: blockchain, type: .btc(restoreMode: restoreMode))
            }

        if let blockchain = try? marketKit.blockchain(uid: BlockchainType.monero.uid) {
            let moneroNode = moneroNodeManager.node(blockchainType: .monero)
            items.append(.init(blockchain: blockchain, type: .monero(node: moneroNode)))
        }

        btcItems = items.sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }

    private func syncEvmItems() {
        evmItems = evmBlockchainManager.allBlockchains
            .map { blockchain in
                let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
                return Item(blockchain: blockchain, type: .evm(syncSource: syncSource))
            }
            .sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }
}

extension BlockchainSettingsViewModel {
    struct Item {
        let blockchain: Blockchain
        let type: ItemType

        var title: String {
            switch type {
            case let .evm(syncSource): return syncSource.name
            case let .btc(restoreMode): return restoreMode.title(blockchain: blockchain)
            case let .monero(node): return node.name
            }
        }
    }

    enum ItemType {
        case evm(syncSource: EvmSyncSource)
        case btc(restoreMode: BtcRestoreMode)
        case monero(node: MoneroNode)
    }
}
