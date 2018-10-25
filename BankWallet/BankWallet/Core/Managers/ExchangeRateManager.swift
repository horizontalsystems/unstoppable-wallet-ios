import RxSwift

class ExchangeRateManager {
    let subject = PublishSubject<[Coin: CurrencyValue]>()
}

extension ExchangeRateManager: IExchangeRateManager {

    var exchangeRates: [Coin: CurrencyValue] {
        return [
            "BTCr": CurrencyValue(currency: DollarCurrency(), value: 1000),
            "ETHt": CurrencyValue(currency: DollarCurrency(), value: 220)
        ]
    }

    func updateRates() {
        subject.onNext([
            "BTCr": CurrencyValue(currency: DollarCurrency(), value: 3000),
            "ETHt": CurrencyValue(currency: DollarCurrency(), value: 300)
        ])
    }

}
