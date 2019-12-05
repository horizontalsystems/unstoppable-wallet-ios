import Foundation

struct TransactionRecord {
    let uid: String
    let transactionHash: String
    let transactionIndex: Int
    let interTransactionIndex: Int
    let type: TransactionType
    let blockHeight: Int?
    let amount: Decimal
    let fee: Decimal?
    let date: Date
    let failed: Bool
    let from: String?
    let to: String?
    let lockInfo: TransactionLockInfo?
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
        lhs.uid == rhs.uid
    }

}

enum TransactionType: Equatable { case incoming, outgoing, sentToSelf }
