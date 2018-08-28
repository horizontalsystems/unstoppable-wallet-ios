import Foundation

struct TransactionRecordViewItem {

    enum Status: String {
        case success = "success", pending = "pending"
    }

    let transactionHash: String
    let amount: CoinValue
    let fee: CoinValue
    let from: String?
    let to: String?
    let incoming: Bool
    let blockHeight: Int?
    let date: Date?
    let status: Status
    let confirmations: Int?

}
