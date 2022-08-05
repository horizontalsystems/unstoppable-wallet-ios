import RxSwift
import RxRelay
import PinKit
import MarketKit

class SecuritySettingsService {
    private let pinKit: IPinKit
    private let btcBlockchainManager: BtcBlockchainManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private let pinItemRelay = PublishRelay<PinItem>()
    private(set) var pinItem: PinItem = PinItem(enabled: false, biometryEnabled: false, biometryType: nil) {
        didSet {
            pinItemRelay.accept(pinItem)
        }
    }

    private let blockchainItemsRelay = PublishRelay<[BlockchainItem]>()
    private(set) var blockchainItems: [BlockchainItem] = [] {
        didSet {
            blockchainItemsRelay.accept(blockchainItems)
        }
    }

    init(pinKit: IPinKit, btcBlockchainManager: BtcBlockchainManager, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.pinKit = pinKit
        self.btcBlockchainManager = btcBlockchainManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, pinKit.isPinSetObservable) { [weak self] _ in self?.syncPinItem() }
        subscribe(disposeBag, pinKit.biometryTypeObservable) { [weak self] _ in self?.syncPinItem() }
        subscribe(disposeBag, btcBlockchainManager.restoreModeUpdatedObservable) { [weak self] _ in self?.syncBlockchainItems() }
        subscribe(disposeBag, btcBlockchainManager.transactionSortModeUpdatedObservable) { [weak self] _ in self?.syncBlockchainItems() }
        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] _ in self?.syncBlockchainItems() }

        syncPinItem()
        syncBlockchainItems()
    }

    private func syncPinItem() {
        pinItem = PinItem(enabled: pinKit.isPinSet, biometryEnabled: pinKit.biometryEnabled, biometryType: pinKit.biometryType)
    }

    private func syncBlockchainItems() {
        let btcBlockchainItems: [BlockchainItem] = btcBlockchainManager.allBlockchains.map { blockchain in
            let restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
            let transactionMode = btcBlockchainManager.transactionSortMode(blockchainType: blockchain.type)
            return BlockchainItem.btc(blockchain: blockchain, restoreMode: restoreMode, transactionMode: transactionMode)
        }

        let evmBlockchainItems: [BlockchainItem] = evmBlockchainManager.allBlockchains.map { blockchain in
            let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchain.type)
            return BlockchainItem.evm(blockchain: blockchain, syncSource: syncSource)
        }

        blockchainItems = (btcBlockchainItems + evmBlockchainItems).sorted { $0.blockchainType.order < $1.blockchainType.order }
    }

}

extension SecuritySettingsService {

    var pinItemObservable: Observable<PinItem> {
        pinItemRelay.asObservable()
    }

    var blockchainItemsObservable: Observable<[BlockchainItem]> {
        blockchainItemsRelay.asObservable()
    }

    func toggleBiometry(isOn: Bool) {
        pinKit.biometryEnabled = isOn
    }

    func disablePin() throws {
        try pinKit.clear()
    }

}

extension SecuritySettingsService {

    struct PinItem {
        let enabled: Bool
        let biometryEnabled: Bool
        let biometryType: BiometryType?
    }

    enum BlockchainItem {
        case btc(blockchain: Blockchain, restoreMode: BtcRestoreMode, transactionMode: TransactionDataSortMode)
        case evm(blockchain: Blockchain, syncSource: EvmSyncSource)

        var blockchainType: BlockchainType {
            switch self {
            case .btc(let blockchain, _, _): return blockchain.type
            case .evm(let blockchain, _): return blockchain.type
            }
        }
    }

}
