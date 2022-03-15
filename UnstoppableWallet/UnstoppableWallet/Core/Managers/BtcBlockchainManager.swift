import RxSwift
import RxRelay
import MarketKit
import BitcoinCore

class BtcBlockchainManager {
    private let storage: BlockchainSettingsStorage

    private let restoreModeUpdatedRelay = PublishRelay<BtcBlockchain>()
    private let transactionSortModeUpdatedRelay = PublishRelay<BtcBlockchain>()

    init(storage: BlockchainSettingsStorage) {
        self.storage = storage
    }

}

extension BtcBlockchainManager {

    var restoreModeUpdatedObservable: Observable<BtcBlockchain> {
        restoreModeUpdatedRelay.asObservable()
    }

    var transactionSortModeUpdatedObservable: Observable<BtcBlockchain> {
        transactionSortModeUpdatedRelay.asObservable()
    }

    func restoreMode(blockchain: BtcBlockchain) -> BtcRestoreMode {
        storage.btcRestoreMode(btcBlockchain: blockchain) ?? .api
    }

    func syncMode(blockchain: BtcBlockchain, accountOrigin: AccountOrigin) -> BitcoinCore.SyncMode {
        if accountOrigin == .created {
            return .newWallet
        }

        switch restoreMode(blockchain: blockchain) {
        case .api: return .api
        case .blockchain: return .full
        }
    }

    func save(restoreMode: BtcRestoreMode, blockchain: BtcBlockchain) {
        storage.save(btcRestoreMode: restoreMode, btcBlockchain: blockchain)
        restoreModeUpdatedRelay.accept(blockchain)
    }

    func transactionSortMode(blockchain: BtcBlockchain) -> TransactionDataSortMode {
        storage.btcTransactionSortMode(btcBlockchain: blockchain) ?? .shuffle
    }

    func save(transactionSortMode: TransactionDataSortMode, blockchain: BtcBlockchain) {
        storage.save(btcTransactionSortMode: transactionSortMode, btcBlockchain: blockchain)
        transactionSortModeUpdatedRelay.accept(blockchain)
    }

}
