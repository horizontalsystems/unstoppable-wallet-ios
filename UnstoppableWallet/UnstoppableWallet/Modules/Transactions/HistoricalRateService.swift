import Foundation
import RxSwift
import CoinKit
import CurrencyKit

class HistoricalRateService {
    private var disposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    private var ratesManager: IRateManager
    private var currency: Currency
    private var rates = [RateKey: CurrencyValue]()

    private var rateUpdatedSubject = PublishSubject<(RateKey, CurrencyValue)>()
    private var ratesChangedSubject = PublishSubject<Void>()

    init(ratesManager: IRateManager, currencyKit: CurrencyKit.Kit) {
        self.ratesManager = ratesManager
        currency = currencyKit.baseCurrency

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] currency in self?.handle(updatedCurrency: currency) }
    }

    private func handle(updatedCurrency: Currency) {
        ratesDisposeBag = DisposeBag()
        currency = updatedCurrency
        rates = [:]
        ratesChangedSubject.onNext(())
    }

    func handle(key: RateKey, rate: Decimal) {
        let rate = CurrencyValue(currency: currency, value: rate)
        rates[key] = rate
        rateUpdatedSubject.onNext((key, rate))
    }

}

extension HistoricalRateService {

    var rateUpdatedObservable: Observable<(RateKey, CurrencyValue)> {
        rateUpdatedSubject.asObservable()
    }

    var ratesChangedObservable: Observable<Void> {
        ratesChangedSubject.asObservable()
    }

    func rate(key: RateKey) -> CurrencyValue? {
        rates[key]
    }

    func fetchRate(key: RateKey) {
        if let rate = rates[key] {
            rateUpdatedSubject.onNext((key, rate))
            return
        }

        ratesManager.historicalRate(coinType: key.coinType, currencyCode: currency.code, timestamp: key.date.timeIntervalSince1970)
                .subscribe(onSuccess: { [weak self] decimal in self?.handle(key: key, rate: decimal) })
                .disposed(by: ratesDisposeBag)
    }

}

struct RateKey: Hashable {

    let coinType: CoinType
    let date: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(coinType)
        hasher.combine(date)
    }

    static func ==(lhs: RateKey, rhs: RateKey) -> Bool {
        lhs.coinType == rhs.coinType && lhs.date == rhs.date
    }

}
