import RxSwift
import RxRelay
import MarketKit

class BtcBlockchainSettingsService {
    let blockchain: Blockchain
    private let btcBlockchainManager: BtcBlockchainManager
    private let disposeBag = DisposeBag()

    var restoreMode: BtcRestoreMode {
        didSet {
            syncHasChanges()
        }
    }

    var transactionMode: TransactionDataSortMode {
        didSet {
            syncHasChanges()
        }
    }

    private let hasChangesRelay = BehaviorRelay<Bool>(value: false)

    init(blockchain: Blockchain, btcBlockchainManager: BtcBlockchainManager) {
        self.blockchain = blockchain
        self.btcBlockchainManager = btcBlockchainManager

        restoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
        transactionMode = btcBlockchainManager.transactionSortMode(blockchainType: blockchain.type)
    }

    private func syncHasChanges() {
        let initialRestoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
        let initialTransactionMode = btcBlockchainManager.transactionSortMode(blockchainType: blockchain.type)

        hasChangesRelay.accept(restoreMode != initialRestoreMode || transactionMode != initialTransactionMode)
    }

}

extension BtcBlockchainSettingsService {

    var hasChangesObservable: Observable<Bool> {
        hasChangesRelay.asObservable()
    }

    func save() {
        if restoreMode != btcBlockchainManager.restoreMode(blockchainType: blockchain.type) {
            btcBlockchainManager.save(restoreMode: restoreMode, blockchainType: blockchain.type)
        }

        if transactionMode != btcBlockchainManager.transactionSortMode(blockchainType: blockchain.type) {
            btcBlockchainManager.save(transactionSortMode: transactionMode, blockchainType: blockchain.type)
        }
    }

}
