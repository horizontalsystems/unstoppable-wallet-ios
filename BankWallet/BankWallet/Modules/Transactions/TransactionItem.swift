import DeepDiff

struct TransactionItem {
    let wallet: Wallet
    let record: TransactionRecord
}

extension TransactionItem: Comparable {

    public static func <(lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record < rhs.record
    }

    public static func ==(lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        lhs.record == rhs.record
    }

}

extension TransactionItem: DiffAware {

    public var diffId: String {
        record.uid
    }

    public static func compareContent(_ a: TransactionItem, _ b: TransactionItem) -> Bool {
        a.record.date == b.record.date &&
                a.record.interTransactionIndex == b.record.interTransactionIndex &&
                a.record.blockHeight == b.record.blockHeight &&
                a.record.failed == b.record.failed &&
                a.record.conflictingHash == b.record.conflictingHash
    }

}
