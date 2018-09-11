import Foundation

enum TransactionStatus {
    case processing
    case verifying(progress: Double)
    case completed
}

struct TransactionAddress {
    let address: String
    let mine: Bool
}

struct TransactionRecord {
    let transactionHash: String
    let from: [TransactionAddress]
    let to: [TransactionAddress]
    let amount: Double
    let status: TransactionStatus
    let timestamp: Int?
}
