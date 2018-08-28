import Foundation
import RxSwift

struct WalletBalanceViewItem {
    let adapterId: String
    let coinValue: CoinValue
    let exchangeValue: CurrencyValue?
    let currencyValue: CurrencyValue?
    let progressSubject: BehaviorSubject<Double>?
}
