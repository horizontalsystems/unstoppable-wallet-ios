import BitcoinCore
import MarketKit
import RxRelay
import RxSwift

class BtcBlockchainManager {
    static let blockchainTypes: [BlockchainType] = [
        .bitcoin,
        .bitcoinCash,
        .ecash,
        .litecoin,
        .dash,
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
            allBlockchains = try marketKit.blockchains(uids: Self.blockchainTypes.map(\.uid))
        } catch {
            allBlockchains = []
        }
    }

    private func fastestSyncMode(blockchainType: BlockchainType) -> BtcRestoreMode {
        blockchainType.supports(restoreMode: .blockchair) ? .blockchair : .hybrid
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
        storage.btcRestoreMode(blockchainType: blockchainType) ?? fastestSyncMode(blockchainType: blockchainType)
    }

    func syncMode(blockchainType: BlockchainType, accountOrigin: AccountOrigin) -> BitcoinCore.SyncMode {
        let _restoreMode = accountOrigin == .created
            ? fastestSyncMode(blockchainType: blockchainType)
            : restoreMode(blockchainType: blockchainType)

        switch _restoreMode {
        case .blockchair: return .blockchair
        case .hybrid: return .api
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

    func transactionRbfEnabled(blockchainType: BlockchainType) -> Bool {
        storage.btcTransactionRbfEnabled(blockchainType: blockchainType) ?? true
    }

    func save(transactionSortMode: TransactionDataSortMode, blockchainType: BlockchainType) {
        storage.save(btcTransactionSortMode: transactionSortMode, blockchainType: blockchainType)
        transactionSortModeUpdatedRelay.accept(blockchainType)
    }

    func save(rbfEnabled: Bool, blockchainType: BlockchainType) {
        storage.save(btcRbfEnabled: rbfEnabled, blockchainType: blockchainType)
    }
}

extension BtcBlockchainManager {
    var backup: [BtcRestoreModeBackup] {
        Self.blockchainTypes.map {
            BtcRestoreModeBackup(
                blockchainTypeUid: $0.uid,
                restoreMode: restoreMode(blockchainType: $0).rawValue,
                sortMode: transactionSortMode(blockchainType: $0).rawValue
            )
        }
    }

    func restore(backup: [BtcRestoreModeBackup]) {
        for backup in backup {
            let type = BlockchainType(uid: backup.blockchainTypeUid)

            if let mode = BtcRestoreMode(rawValue: backup.restoreMode) {
                save(restoreMode: mode, blockchainType: type)
            }
            if let mode = TransactionDataSortMode(rawValue: backup.sortMode) {
                save(transactionSortMode: mode, blockchainType: type)
            }
        }
    }
}

extension BtcBlockchainManager {
    struct BtcRestoreModeBackup: Codable {
        let blockchainTypeUid: String
        let restoreMode: String
        let sortMode: String

        enum CodingKeys: String, CodingKey {
            case blockchainTypeUid = "blockchain_type_id"
            case restoreMode = "restore_mode"
            case sortMode = "sort_mode"
        }
    }
}
