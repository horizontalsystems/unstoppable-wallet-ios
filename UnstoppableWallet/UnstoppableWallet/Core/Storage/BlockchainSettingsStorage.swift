import MarketKit

class BlockchainSettingsStorage {
    private let storage: BlockchainSettingRecordStorage

    private let keyBtcRestore = "btc-restore"
    private let keyBtcTransactionSort = "btc-transaction-sort"
    private let keyBtcTransactionRbf = "btc-transaction-rbf"
    private let keyEvmSyncSource = "evm-sync-source"

    init(storage: BlockchainSettingRecordStorage) {
        self.storage = storage
    }
}

extension BlockchainSettingsStorage {
    func btcRestoreMode(blockchainType: BlockchainType) -> BtcRestoreMode? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyBtcRestore)
            .flatMap { record in
                BtcRestoreMode(rawValue: record.value)
            }
    }

    func save(btcRestoreMode: BtcRestoreMode, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyBtcRestore, value: btcRestoreMode.rawValue)
        try? storage.save(record: record)
    }

    func btcTransactionSortMode(blockchainType: BlockchainType) -> TransactionDataSortMode? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyBtcTransactionSort)
            .flatMap { record in
                TransactionDataSortMode(rawValue: record.value)
            }
    }

    func save(btcTransactionSortMode: TransactionDataSortMode, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyBtcTransactionSort, value: btcTransactionSortMode.rawValue)
        try? storage.save(record: record)
    }

    func btcTransactionRbfEnabled(blockchainType: BlockchainType) -> Bool? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyBtcTransactionRbf)
            .flatMap { record in
                Bool(record.value)
            }
    }

    func save(btcRbfEnabled: Bool, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyBtcTransactionRbf, value: String(btcRbfEnabled))
        try? storage.save(record: record)
    }

    func evmSyncSourceUrl(blockchainType: BlockchainType) -> String? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyEvmSyncSource).map(\.value)
    }

    func save(evmSyncSourceUrl: String, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyEvmSyncSource, value: evmSyncSourceUrl)
        try? storage.save(record: record)
    }
}
