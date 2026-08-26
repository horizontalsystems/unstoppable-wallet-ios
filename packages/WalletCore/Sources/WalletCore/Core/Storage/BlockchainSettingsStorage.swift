import MarketKit

public class BlockchainSettingsStorage {
    private let storage: BlockchainSettingRecordStorage

    private let keyBtcRestore = "btc-restore"
    private let keyBtcTransactionSort = "btc-transaction-sort"
    private let keyBtcTransactionRbf = "btc-transaction-rbf"
    private let keyEvmSyncSource = "evm-sync-source"
    private let keyThorChainEndpointFamily = "thorchain-endpoint-family"
    private let keyMoneroNode = "monero-node"
    private let keyMoneroAutoSelect = "monero-auto-select"
    private let keyZanoNode = "zano-node"
    private let keyZcashNode = "zcash-node"
    private let keyEndpointAutoSelect = "endpoint-auto-select"

    public init(storage: BlockchainSettingRecordStorage) {
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

    func thorChainEndpointFamilyId(blockchainType: BlockchainType) -> String? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyThorChainEndpointFamily).map(\.value)
    }

    func save(thorChainEndpointFamilyId: String, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyThorChainEndpointFamily, value: thorChainEndpointFamilyId)
        try? storage.save(record: record)
    }

    func moneroNodeUrl(blockchainType: BlockchainType) -> String? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyMoneroNode).map(\.value)
    }

    func save(moneroNodeUrl: String, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyMoneroNode, value: moneroNodeUrl)
        try? storage.save(record: record)
    }

    func moneroAutoSelectEnabled(blockchainType: BlockchainType) -> Bool {
        ((try? storage.record(blockchainUid: blockchainType.uid, key: keyMoneroAutoSelect))?.map { $0.value == "true" }) ?? false
    }

    func save(moneroAutoSelectEnabled: Bool, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyMoneroAutoSelect, value: moneroAutoSelectEnabled ? "true" : "false")
        try? storage.save(record: record)
    }

    func zanoNodeUrl(blockchainType: BlockchainType) -> String? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyZanoNode).map(\.value)
    }

    func save(zanoNodeUrl: String, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyZanoNode, value: zanoNodeUrl)
        try? storage.save(record: record)
    }

    // Chain-agnostic flag: explicit values win, absent/malformed falls back to the chain's
    // default (a corrupted record must not flip the feature). Monero keeps its legacy key.
    func endpointAutoSelectEnabled(blockchainType: BlockchainType) -> Bool {
        switch try? storage.record(blockchainUid: blockchainType.uid, key: keyEndpointAutoSelect)?.value {
        case "true": return true
        case "false": return false
        default: return Self.defaultEndpointAutoSelect(blockchainType: blockchainType)
        }
    }

    func save(endpointAutoSelectEnabled: Bool, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyEndpointAutoSelect, value: endpointAutoSelectEnabled ? "true" : "false")
        try? storage.save(record: record)
    }

    private static func defaultEndpointAutoSelect(blockchainType: BlockchainType) -> Bool {
        switch blockchainType {
        case .zcash: return true
        default: return false
        }
    }

    func zcashNodeUrl(blockchainType: BlockchainType) -> String? {
        try? storage.record(blockchainUid: blockchainType.uid, key: keyZcashNode).map(\.value)
    }

    func save(zcashNodeUrl: String, blockchainType: BlockchainType) {
        let record = BlockchainSettingRecord(blockchainUid: blockchainType.uid, key: keyZcashNode, value: zcashNodeUrl)
        try? storage.save(record: record)
    }
}
