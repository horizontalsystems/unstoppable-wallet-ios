import Foundation
import WalletKit

enum TransactionStatus {
    case processing
    case verifying(progress: Double)
    case completed
}

struct TransactionRecord {
    let transactionHash: String
    let from: [TransactionAddress]
    let to: [TransactionAddress]
    let amount: Double
    let status: TransactionStatus
    let timestamp: Int?
}
