import MarketKit

class BlockchainSettingsStorage {
    private let storage: BlockchainSettingRecordStorage

    private let keyBtcRestore = "btc-restore"
    private let keyBtcTransactionSort = "btc-transaction-sort"
    private let keyEvmSyncSource = "evm-sync-source"

    init(storage: BlockchainSettingRecordStorage) {
        self.storage = storage
    }

}

extension BlockchainSettingsStorage {

    func btcRestoreMode(btcBlockchain: BtcBlockchain) -> BtcRestoreMode? {
        try? storage.record(blockchainUid: btcBlockchain.rawValue, key: keyBtcRestore)
                .flatMap { record in
                    BtcRestoreMode(rawValue: record.value)
                }
    }

    func save(btcRestoreMode: BtcRestoreMode, btcBlockchain: BtcBlockchain) {
        let record = BlockchainSettingRecord(blockchainUid: btcBlockchain.rawValue, key: keyBtcRestore, value: btcRestoreMode.rawValue)
        try? storage.save(record: record)
    }

    func btcTransactionSortMode(btcBlockchain: BtcBlockchain) -> TransactionDataSortMode? {
        try? storage.record(blockchainUid: btcBlockchain.rawValue, key: keyBtcTransactionSort)
                .flatMap { record in
                    TransactionDataSortMode(rawValue: record.value)
                }
    }

    func save(btcTransactionSortMode: TransactionDataSortMode, btcBlockchain: BtcBlockchain) {
        let record = BlockchainSettingRecord(blockchainUid: btcBlockchain.rawValue, key: keyBtcTransactionSort, value: btcTransactionSortMode.rawValue)
        try? storage.save(record: record)
    }

    func evmSyncSourceName(evmBlockchain: EvmBlockchain) -> String? {
        try? storage.record(blockchainUid: evmBlockchain.rawValue, key: keyEvmSyncSource).flatMap { $0.value }
    }

    func save(evmSyncSourceName: String, evmBlockchain: EvmBlockchain) {
        let record = BlockchainSettingRecord(blockchainUid: evmBlockchain.rawValue, key: keyEvmSyncSource, value: evmSyncSourceName)
        try? storage.save(record: record)
    }

}
