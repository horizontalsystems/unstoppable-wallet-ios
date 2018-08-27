import Foundation
import RxSwift

class ExchangeRateManager {
    static let shared = ExchangeRateManager()

    let subject = PublishSubject<[String: Double]>()

    var exchangeRates: [String: Double] {
        return ["BTC-R": 1000]
    }

    func updateRates() {
        subject.onNext(["BTC-R": 3000])
    }

}
