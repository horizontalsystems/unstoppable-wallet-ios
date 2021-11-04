import Foundation
import RxSwift
import MarketKit
import CurrencyKit

class HistoricalRateService {
    private var disposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    private var marketKit: MarketKit.Kit
    private var currency: Currency
    private var rates = [RateKey: CurrencyValue]()

    private var rateUpdatedSubject = PublishSubject<(RateKey, CurrencyValue)>()
    private var ratesChangedSubject = PublishSubject<Void>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions-historical-rate-service-queue", qos: .userInitiated)

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        currency = currencyKit.baseCurrency

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] currency in self?.handle(updatedCurrency: currency) }
    }

    private func handle(updatedCurrency: Currency) {
        ratesDisposeBag = DisposeBag()
        currency = updatedCurrency
        queue.async { self.rates = [:] }
        ratesChangedSubject.onNext(())
    }

    private func handle(key: RateKey, rate: Decimal) {
        let rate = CurrencyValue(currency: currency, value: rate)
        queue.async { self.rates[key] = rate }
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
        queue.sync { rates[key] }
    }

    func fetchRate(key: RateKey) {
        if let rate = rates[key] {
            rateUpdatedSubject.onNext((key, rate))
            return
        }

        marketKit.coinHistoricalPriceValueSingle(coinUid: key.coin.uid, currencyCode: currency.code, timestamp: key.date.timeIntervalSince1970)
                .subscribe(onSuccess: { [weak self] decimal in self?.handle(key: key, rate: decimal) })
                .disposed(by: ratesDisposeBag)
    }

}

struct RateKey: Hashable {

    let coin: Coin
    let date: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(coin)
        hasher.combine(date)
    }

    static func ==(lhs: RateKey, rhs: RateKey) -> Bool {
        lhs.coin == rhs.coin && lhs.date == rhs.date
    }

}
