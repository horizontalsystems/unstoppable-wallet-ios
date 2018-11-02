import Foundation

struct TransactionRecordViewItem {
    let transactionHash: String
    let coinValue: CoinValue
    let currencyAmount: CurrencyValue?
    let from: String?
    let to: String?
    let incoming: Bool
    let date: Date?
    let status: TransactionStatus
}
