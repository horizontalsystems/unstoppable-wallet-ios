import Foundation

struct TransactionRecord {
    let transactionHash: String
    let from: [String]
    let to: [String]
    let amount: Double
    let fee: Double
    let blockHeight: Int?
    let timestamp: Int?
}
