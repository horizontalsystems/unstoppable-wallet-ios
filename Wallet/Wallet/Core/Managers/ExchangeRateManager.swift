import RxSwift

class ExchangeRateManager {
    let subject = PublishSubject<[String: Double]>()
}

extension ExchangeRateManager: IExchangeRateManager {

    var exchangeRates: [String: Double] {
        return ["rBTC": 1000, "kETH" : 220]
    }

    func updateRates() {
        subject.onNext(["rBTC": 3000, "kETH" : 220])
    }

}
