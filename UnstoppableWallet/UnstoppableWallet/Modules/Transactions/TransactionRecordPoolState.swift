class TransactionRecordPoolState {
    let wallet: TransactionWallet

    var records = [TransactionRecord]()
    var firstUnusedIndex = 0
    var allLoaded = false

    init(wallet: TransactionWallet) {
        self.wallet = wallet
    }

    var unusedRecords: [TransactionRecord] {
        Array(records.suffix(from: firstUnusedIndex))
    }

    func add(records: [TransactionRecord]) {
        self.records.append(contentsOf: records)
    }

    func index(ofRecord record: TransactionRecord) -> Int? {
        records.firstIndex(of: record)
    }

    func insertIndex(ofRecord record: TransactionRecord) -> Int? {
        records.firstIndex(where: { $0 < record })
    }

    func set(record: TransactionRecord, atIndex index: Int) {
        records[index] = record
    }

    func insert(record: TransactionRecord, atIndex index: Int) {
        records.insert(record, at: index)
    }

}
