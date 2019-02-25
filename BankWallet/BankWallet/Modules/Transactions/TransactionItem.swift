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
