import Foundation
import DeepDiff

class TransactionViewItem {
    let wallet: Wallet
    let transactionHash: String
    let coinValue: CoinValue
    let feeCoinValue: CoinValue?
    let currencyValue: CurrencyValue?
    let from: String?
    let to: String?
    let type: TransactionType
    let showFromAddress: Bool
    let date: Date
    let status: TransactionStatus
    let rate: CurrencyValue?
    let lockInfo: TransactionLockInfo?

    init(wallet: Wallet, transactionHash: String, coinValue: CoinValue, feeCoinValue: CoinValue?,
         currencyValue: CurrencyValue?, from: String?, to: String?, type: TransactionType,
         showFromAddress: Bool, date: Date, status: TransactionStatus, rate: CurrencyValue?, lockInfo: TransactionLockInfo?) {
        self.wallet = wallet
        self.transactionHash = transactionHash
        self.coinValue = coinValue
        self.feeCoinValue = feeCoinValue
        self.currencyValue = currencyValue
        self.from = from
        self.to = to
        self.type = type
        self.showFromAddress = showFromAddress
        self.date = date
        self.status = status
        self.rate = rate
        self.lockInfo = lockInfo
    }
}

extension TransactionViewItem: DiffAware {

    public var diffId: String {
        transactionHash
    }

    public static func compareContent(_ a: TransactionViewItem, _ b: TransactionViewItem) -> Bool {
        a.date == b.date &&
                a.currencyValue == b.currencyValue &&
                a.rate == b.rate &&
                a.status == b.status
    }

}
