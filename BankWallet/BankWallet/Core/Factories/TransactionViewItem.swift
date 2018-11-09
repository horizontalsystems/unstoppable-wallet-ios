import Foundation

struct TransactionViewItem {
    let transactionHash: String
    let coinValue: CoinValue
    let currencyValue: CurrencyValue?
    let from: String?
    let to: String?
    let incoming: Bool
    let date: Date?
    let status: TransactionStatus
}
