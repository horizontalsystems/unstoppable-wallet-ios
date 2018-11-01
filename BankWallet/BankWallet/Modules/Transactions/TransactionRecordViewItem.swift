import Foundation

struct TransactionRecordViewItem {
    let transactionHash: String
    let amount: CoinValue
    let currencyAmount: CurrencyValue?
    let from: String?
    let to: String?
    let incoming: Bool
    let date: Date?
    let status: TransactionStatus
}
