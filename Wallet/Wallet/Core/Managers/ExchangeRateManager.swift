import RxSwift

class ExchangeRateManager {
    let subject = PublishSubject<[String: Double]>()
}

extension ExchangeRateManager: IExchangeRateManager {

    var exchangeRates: [String: Double] {
        return ["BTCr": 1000, "ETHt" : 220]
    }

    func updateRates() {
        subject.onNext(["BTCr": 3000, "ETHt" : 220])
    }

}
