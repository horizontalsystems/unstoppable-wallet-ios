import RxSwift

struct WalletViewItem {
    let coinValue: CoinValue
    let exchangeValue: CurrencyValue?
    let currencyValue: CurrencyValue?
    let progressSubject: BehaviorSubject<Double>?
}
