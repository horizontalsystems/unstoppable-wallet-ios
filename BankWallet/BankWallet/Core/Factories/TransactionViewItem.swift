import Foundation

class TransactionViewItem {
    let coin: Coin
    let transactionHash: String
    let coinValue: CoinValue
    let currencyValue: CurrencyValue?
    let from: String?
    let to: String?
    let incoming: Bool
    let date: Date?
    let status: TransactionStatus
    let rate: CurrencyValue?

    init(coin: Coin, transactionHash: String, coinValue: CoinValue, currencyValue: CurrencyValue?, from: String?, to: String?, incoming: Bool, date: Date?, status: TransactionStatus, rate: CurrencyValue?) {
        self.coin = coin
        self.transactionHash = transactionHash
        self.coinValue = coinValue
        self.currencyValue = currencyValue
        self.from = from
        self.to = to
        self.incoming = incoming
        self.date = date
        self.status = status
        self.rate = rate
    }
}
