import Foundation
import RxSwift
import BitcoinKit

class StubExchangeRateProvider: IExchangeRateProvider {
    let subject = PublishSubject<[String: Double]>()

    func getExchangeRate(forCoin coin: Coin) -> Double {
        return 7200
    }

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: { [weak self] in
            self?.subject.onNext([Bitcoin().code: 14400])
        })
    }

}
