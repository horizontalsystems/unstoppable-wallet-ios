import Foundation
import RxSwift

class ExchangeRateManager {
    static let shared = ExchangeRateManager()

    let subject = PublishSubject<[String: Double]>()

    var exchangeRates: [String: Double] {
        return ["rBTC": 1000]
    }

    func updateRates() {
        subject.onNext(["rBTC": 3000])
    }

}
