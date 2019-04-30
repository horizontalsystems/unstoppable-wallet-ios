import Foundation

struct TransactionRecord {
    let transactionHash: String
    let transactionIndex: Int
    let interTransactionIndex: Int
    let blockHeight: Int?
    let amount: Decimal
    let date: Date

    let from: [TransactionAddress]
    let to: [TransactionAddress]
}

struct TransactionAddress {
    let address: String
    let mine: Bool
}

extension TransactionRecord: Comparable {

    public static func <(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        guard lhs.date == rhs.date else {
            return lhs.date < rhs.date
        }

        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex < rhs.transactionIndex
        }

        return lhs.interTransactionIndex < rhs.interTransactionIndex
    }

    public static func ==(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        return lhs.transactionHash == rhs.transactionHash && lhs.interTransactionIndex == rhs.interTransactionIndex
    }

}
