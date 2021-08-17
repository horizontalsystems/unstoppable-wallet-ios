import Foundation
import RxSwift
import CoinKit
import CurrencyKit

class HistoricalRateService {
    private var disposeBag = DisposeBag()

    private var ratesManager: IRateManager
    private var currency: Currency
    private var rates = [RateKey: CurrencyValue]()

    private var rateUpdatedSubject = PublishSubject<(RateKey, CurrencyValue)>()
    private var ratesExpiredSubject = PublishSubject<Void>()

    init(ratesManager: IRateManager, currencyKit: CurrencyKit.Kit) {
        self.ratesManager = ratesManager
        currency = currencyKit.baseCurrency

        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] currency in
                    self?.handle(updatedCurrency: currency)
                })
                .disposed(by: disposeBag)
    }

    private func handle(updatedCurrency: Currency) {
        disposeBag = DisposeBag()
        rates = [:]
        ratesExpiredSubject.onNext(())
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

    var ratesExpiredObservable: Observable<Void> {
        ratesExpiredSubject.asObservable()
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
                .disposed(by: disposeBag)
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
