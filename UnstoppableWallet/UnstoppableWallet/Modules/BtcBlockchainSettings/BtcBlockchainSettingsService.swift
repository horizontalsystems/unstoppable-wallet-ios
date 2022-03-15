import RxSwift
import RxRelay

class BtcBlockchainSettingsService {
    let blockchain: BtcBlockchain
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

    init(blockchain: BtcBlockchain, btcBlockchainManager: BtcBlockchainManager) {
        self.blockchain = blockchain
        self.btcBlockchainManager = btcBlockchainManager

        restoreMode = btcBlockchainManager.restoreMode(blockchain: blockchain)
        transactionMode = btcBlockchainManager.transactionSortMode(blockchain: blockchain)
    }

    private func syncHasChanges() {
        let initialRestoreMode = btcBlockchainManager.restoreMode(blockchain: blockchain)
        let initialTransactionMode = btcBlockchainManager.transactionSortMode(blockchain: blockchain)

        hasChangesRelay.accept(restoreMode != initialRestoreMode || transactionMode != initialTransactionMode)
    }

}

extension BtcBlockchainSettingsService {

    var hasChangesObservable: Observable<Bool> {
        hasChangesRelay.asObservable()
    }

    func save() {
        if restoreMode != btcBlockchainManager.restoreMode(blockchain: blockchain) {
            btcBlockchainManager.save(restoreMode: restoreMode, blockchain: blockchain)
        }

        if transactionMode != btcBlockchainManager.transactionSortMode(blockchain: blockchain) {
            btcBlockchainManager.save(transactionSortMode: transactionMode, blockchain: blockchain)
        }
    }

}
