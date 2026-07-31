import BitcoinCore
import Combine
import MarketKit
import RxRelay
import RxSwift
import ThorChainKit

class BlockchainSettingsViewModel: ObservableObject {
    private let btcBlockchainManager: BtcBlockchainManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let moneroNodeManager: MoneroNodeManager
    private let zanoNodeManager: ZanoNodeManager
    private let zcashNodeManager: ZcashNodeManager
    private let thorChainEndpointManager: ThorChainEndpointManager
    private let marketKit: MarketKit.Kit
    private let disposeBag = DisposeBag()

    @Published var evmItems: [Item] = []
    @Published var btcItems: [Item] = []
    @Published var tronItem: Item?
    @Published var thorChainItem: Item?

    init(btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, moneroNodeManager: MoneroNodeManager, zanoNodeManager: ZanoNodeManager, zcashNodeManager: ZcashNodeManager, thorChainEndpointManager: ThorChainEndpointManager, marketKit: MarketKit.Kit) {
        self.btcBlockchainManager = btcBlockchainManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.moneroNodeManager = moneroNodeManager
        self.zanoNodeManager = zanoNodeManager
        self.zcashNodeManager = zcashNodeManager
        self.thorChainEndpointManager = thorChainEndpointManager
        self.marketKit = marketKit

        subscribe(MainScheduler.instance, disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(MainScheduler.instance, disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] blockchainType in
            if blockchainType == .tron {
                self?.syncTronItem()
            } else {
                self?.syncEvmItems()
            }
        }
        subscribe(MainScheduler.instance, disposeBag, moneroNodeManager.nodeObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(MainScheduler.instance, disposeBag, zanoNodeManager.nodeObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(MainScheduler.instance, disposeBag, zcashNodeManager.nodeObservable) { [weak self] _ in self?.syncBtcItems() }
        subscribe(MainScheduler.instance, disposeBag, thorChainEndpointManager.endpointObservable) { [weak self] in self?.syncThorChainItem() }

        syncBtcItems()
        syncEvmItems()
        syncTronItem()
        syncThorChainItem()
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

        if let blockchain = try? marketKit.blockchain(uid: BlockchainType.zano.uid) {
            let zanoNode = zanoNodeManager.node(blockchainType: .zano)
            items.append(.init(blockchain: blockchain, type: .zano(node: zanoNode)))
        }

        if let blockchain = try? marketKit.blockchain(uid: BlockchainType.zcash.uid) {
            let zcashNode = zcashNodeManager.node(blockchainType: .zcash)
            items.append(.init(blockchain: blockchain, type: .zcash(node: zcashNode)))
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

    private func syncTronItem() {
        guard let blockchain = try? marketKit.blockchain(uid: BlockchainType.tron.uid) else { return }
        let syncSource = evmSyncSourceManager.syncSource(blockchainType: .tron)
        tronItem = Item(blockchain: blockchain, type: .evm(syncSource: syncSource))
    }

    private func syncThorChainItem() {
        guard let blockchain = try? marketKit.blockchain(uid: BlockchainType.thorChain.uid),
              let endpointFamily = try? thorChainEndpointManager.endpointFamily()
        else {
            thorChainItem = nil
            return
        }

        thorChainItem = Item(blockchain: blockchain, type: .thorChain(endpointFamily: endpointFamily))
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
            case let .zano(node): return node.name
            case let .zcash(node): return node.name
            case let .thorChain(endpointFamily): return endpointFamily.id
            }
        }
    }

    enum ItemType {
        case evm(syncSource: EvmSyncSource)
        case btc(restoreMode: BtcRestoreMode)
        case monero(node: MoneroNode)
        case zano(node: ZanoNode)
        case zcash(node: ZcashNode)
        case thorChain(endpointFamily: ThorChainKit.EndpointFamilyDescriptor)
    }
}
