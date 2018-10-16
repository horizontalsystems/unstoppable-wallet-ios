import Foundation
import WalletKit

enum TransactionStatus {
    case processing
    case verifying(progress: Double)
    case completed
}

public struct TransactionAddress {
    public let address: String
    public let mine: Bool
}

struct TransactionRecord {
    let transactionHash: String
    let from: [TransactionAddress]
    let to: [TransactionAddress]
    let amount: Double
    let status: TransactionStatus
    let timestamp: Int?
}
