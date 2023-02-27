import RxSwift
import RxRelay
import MarketKit
import BitcoinCore

class BtcBlockchainManager {
    private let blockchainTypes: [BlockchainType] = [
        .bitcoin,
        .bitcoinCash,
        .litecoin,
        .dash
    ]

    private let marketKit: MarketKit.Kit
    private let storage: BlockchainSettingsStorage

    private let restoreModeUpdatedRelay = PublishRelay<BlockchainType>()
    private let transactionSortModeUpdatedRelay = PublishRelay<BlockchainType>()

    let allBlockchains: [Blockchain]

    init(marketKit: MarketKit.Kit, storage: BlockchainSettingsStorage) {
        self.marketKit = marketKit
        self.storage = storage

        do {
            allBlockchains = try marketKit.blockchains(uids: blockchainTypes.map { $0.uid })
        } catch {
            allBlockchains = []
        }
    }

}

extension BtcBlockchainManager {

    func blockchain(token: Token) -> Blockchain? {
        allBlockchains.first(where: { token.blockchain == $0 })
    }

    var restoreModeUpdatedObservable: Observable<BlockchainType> {
        restoreModeUpdatedRelay.asObservable()
    }

    var transactionSortModeUpdatedObservable: Observable<BlockchainType> {
        transactionSortModeUpdatedRelay.asObservable()
    }

    func restoreMode(blockchainType: BlockchainType) -> BtcRestoreMode {
        storage.btcRestoreMode(blockchainType: blockchainType) ?? .api
    }

    func syncMode(blockchainType: BlockchainType, accountOrigin: AccountOrigin) -> BitcoinCore.SyncMode {
        if accountOrigin == .created {
            return .newWallet
        }

        switch restoreMode(blockchainType: blockchainType) {
        case .api: return .api
        case .blockchain: return .full
        }
    }

    func save(restoreMode: BtcRestoreMode, blockchainType: BlockchainType) {
        storage.save(btcRestoreMode: restoreMode, blockchainType: blockchainType)
        restoreModeUpdatedRelay.accept(blockchainType)
    }

    func transactionSortMode(blockchainType: BlockchainType) -> TransactionDataSortMode {
        storage.btcTransactionSortMode(blockchainType: blockchainType) ?? .shuffle
    }

    func save(transactionSortMode: TransactionDataSortMode, blockchainType: BlockchainType) {
        storage.save(btcTransactionSortMode: transactionSortMode, blockchainType: blockchainType)
        transactionSortModeUpdatedRelay.accept(blockchainType)
    }

}
