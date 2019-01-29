import RxSwift

class RateManager {
    private let latestRateFallbackThreshold: Double = 60 // in minutes

    private let disposeBag = DisposeBag()

    private let storage: IRateStorage
    private let networkManager: IRateNetworkManager

    init(storage: IRateStorage, networkManager: IRateNetworkManager) {
        self.storage = storage
        self.networkManager = networkManager
    }

    private func sync(coinCode: CoinCode, currencyCode: String, timestamp: Double) {
        let date = Date(timeIntervalSince1970: timestamp)

        networkManager.getRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] value in
                    let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: value, timestamp: timestamp, isLatest: false)
                    self?.storage.save(rate: rate)
                })
                .disposed(by: disposeBag)
    }

    private func latestRateFallbackObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Decimal>? {
        let currentTimestamp = Date().timeIntervalSince1970

        guard timestamp > currentTimestamp - 60 * latestRateFallbackThreshold else {
            return nil
        }

        return storage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                .flatMap { rate -> Observable<Decimal> in
                    guard !rate.expired else {
                        return Observable.empty()
                    }

                    return Observable.just(rate.value)
                }
    }

}

extension RateManager: IRateManager {

    func refreshLatestRates(coinCodes: [CoinCode], currencyCode: String) {
        for coinCode in coinCodes {
            networkManager.getLatestRate(coinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribe(onNext: { [weak self] latestRate in
                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: latestRate.value, timestamp: latestRate.timestamp, isLatest: true)
                        self?.storage.save(latestRate: rate)
                    })
                    .disposed(by: disposeBag)
        }
    }

    func syncZeroValueTimestampRates(currencyCode: String) {
        storage.zeroValueTimestampRatesObservable(currencyCode: currencyCode)
                .take(1)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] rates in
                    for rate in rates {
                        self?.sync(coinCode: rate.coinCode, currencyCode: rate.currencyCode, timestamp: rate.timestamp)
                    }
                })
                .disposed(by: disposeBag)
    }

    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Decimal> {
        return storage.timestampRateObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                .flatMap { [weak self] rate -> Observable<Decimal> in
                    if let rate = rate {
                        if rate.value != 0 {
                            return Observable.just(rate.value)
                        }
                    } else {
                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: 0, timestamp: timestamp, isLatest: false)
                        self?.storage.save(rate: rate)

                        self?.sync(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                    }

                    return self?.latestRateFallbackObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp) ?? Observable.empty()
                }
    }

    func clear() {
        storage.clearRates()
    }

}
