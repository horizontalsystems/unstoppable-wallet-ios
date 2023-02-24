import MarketKit

class BlockchainSettingsStorage {
    private let storage: BlockchainSettingRecordStorage

    private let keyBtcRestore = "btc-restore"
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

    func evmSyncSourceUrl(blockchainType: BlockchainType) -> String? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyEvmSyncSource).flatMap { $0.value }
    }

    func save(evmSyncSourceUrl: String, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyEvmSyncSource, value: evmSyncSourceUrl)
        try? storage.save(record: record)
    }

}
