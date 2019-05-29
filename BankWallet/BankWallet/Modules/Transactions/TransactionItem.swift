import DeepDiff

struct TransactionItem {
    let coin: Coin
    let record: TransactionRecord
}

extension TransactionItem: Comparable {

    public static func <(lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        return lhs.record < rhs.record
    }

    public static func ==(lhs: TransactionItem, rhs: TransactionItem) -> Bool {
        return lhs.record == rhs.record
    }

}

extension TransactionItem: DiffAware {

    public var diffId: String {
        return record.transactionHash
    }

    public static func compareContent(_ a: TransactionItem, _ b: TransactionItem) -> Bool {
        return
                a.record.date                   == b.record.date &&
                a.record.interTransactionIndex  == b.record.interTransactionIndex &&
                a.record.blockHeight            == b.record.blockHeight
    }

}
