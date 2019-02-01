import Foundation

struct TransactionRecord {
    let transactionHash: String
    let blockHeight: Int?
    let amount: Decimal
    let timestamp: Double

    let from: [TransactionAddress]
    let to: [TransactionAddress]
}

struct TransactionAddress {
    let address: String
    let mine: Bool
}

extension TransactionRecord: Comparable {

    public static func <(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }

    public static func ==(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        return lhs.transactionHash == rhs.transactionHash
    }

}
