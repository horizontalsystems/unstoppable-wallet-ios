import RxSwift

class ExchangeRateManager {
    let subject = PublishSubject<[Coin: CurrencyValue]>()
}

extension ExchangeRateManager: IExchangeRateManager {

    var exchangeRates: [Coin: CurrencyValue] {
        return [
            "BTC": CurrencyValue(currency: DollarCurrency(), value: 6500),
            "BTCt": CurrencyValue(currency: DollarCurrency(), value: 6500),
            "BTCr": CurrencyValue(currency: DollarCurrency(), value: 6500),
            "BCH": CurrencyValue(currency: DollarCurrency(), value: 450),
            "BCHt": CurrencyValue(currency: DollarCurrency(), value: 450),
            "ETH": CurrencyValue(currency: DollarCurrency(), value: 220),
            "ETHt": CurrencyValue(currency: DollarCurrency(), value: 220)
        ]
    }

    func updateRates() {
    }

}
