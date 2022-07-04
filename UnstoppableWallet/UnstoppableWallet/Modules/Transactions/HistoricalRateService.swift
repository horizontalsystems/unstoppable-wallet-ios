import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class HistoricalRateService {
    private let marketKit: MarketKit.Kit
    private let disposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    private var currency: Currency
    private var rates = [RateKey: CurrencyValue]()

    private let rateUpdatedRelay = PublishRelay<(RateKey, CurrencyValue)>()
    private let ratesChangedRelay = PublishRelay<Void>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions-historical-rate-service-queue", qos: .userInitiated)

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        currency = currencyKit.baseCurrency

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] in self?.handleUpdated(currency: $0) }
    }

    private func handleUpdated(currency: Currency) {
        ratesDisposeBag = DisposeBag()
        ratesChangedRelay.accept(())

        queue.async {
            self.currency = currency
            self.rates = [:]
        }
    }

    private func handle(key: RateKey, rate: Decimal) {
        queue.async {
            let rate = CurrencyValue(currency: self.currency, value: rate)
            self.rates[key] = rate
            self.rateUpdatedRelay.accept((key, rate))
        }
    }

    private func _fetchRate(key: RateKey) {
        marketKit.coinHistoricalPriceValueSingle(coinUid: key.coinUid, currencyCode: currency.code, timestamp: key.date.timeIntervalSince1970)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] decimal in
                    self?.handle(key: key, rate: decimal)
                })
                .disposed(by: ratesDisposeBag)
    }

}

extension HistoricalRateService {

    var rateUpdatedObservable: Observable<(RateKey, CurrencyValue)> {
        rateUpdatedRelay.asObservable()
    }

    var ratesChangedObservable: Observable<Void> {
        ratesChangedRelay.asObservable()
    }

    func rate(key: RateKey) -> CurrencyValue? {
        queue.sync {
            if let currencyValue = rates[key] {
                return currencyValue
            }

            if let value = marketKit.coinHistoricalPriceValue(coinUid: key.coinUid, currencyCode: currency.code, timestamp: key.date.timeIntervalSince1970) {
                let currencyValue = CurrencyValue(currency: currency, value: value)
                rates[key]  = currencyValue
                return currencyValue
            }

            return nil
        }
    }

    func fetchRate(key: RateKey) {
        queue.async {
            if self.rates[key] == nil {
                self._fetchRate(key: key)
            }
        }
    }

}

struct RateKey: Hashable {
    let coinUid: String
    let date: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(coinUid)
        hasher.combine(date)
    }

    static func ==(lhs: RateKey, rhs: RateKey) -> Bool {
        lhs.coinUid == rhs.coinUid && lhs.date == rhs.date
    }

}
