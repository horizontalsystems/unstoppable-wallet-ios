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

    private func latestRateFallbackObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Decimal?> {
        let currentTimestamp = Date().timeIntervalSince1970

        guard timestamp > currentTimestamp - 60 * latestRateFallbackThreshold else {
            return Observable.just(nil)
        }

        return storage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                .map { rate -> Decimal? in
                    guard !rate.expired else {
                        return nil
                    }

                    return rate.value
                }
    }

}

extension RateManager: IRateManager {

    func refreshLatestRates(coinCodes: [CoinCode], currencyCode: String) {
        networkManager.getLatestRateData(currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] latestRateData in
                    for coinCode in coinCodes {
                        guard let rateValue = latestRateData.values[coinCode] else {
                            continue
                        }

                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: rateValue, timestamp: latestRateData.timestamp, isLatest: true)
                        self?.storage.save(latestRate: rate)
                    }
                })
                .disposed(by: disposeBag)
    }

    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Single<Decimal?> {
        return storage.timestampRateObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                .take(1)
                .flatMap { [unowned self] rate -> Observable<Decimal?> in
                    if let rate = rate {
                        return Observable.just(rate.value)
                    } else {
                        let date = Date(timeIntervalSince1970: timestamp)

                        let networkObservable = self.networkManager.getRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
                                .do(onNext: { [weak self] value in
                                    if let value = value {
                                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: value, timestamp: timestamp, isLatest: false)
                                        self?.storage.save(rate: rate)
                                    }
                                })

                        return networkObservable.catchError { error in
                            return self.latestRateFallbackObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                        }
                    }
                }
                .asSingle()
    }

    func clear() {
        storage.clearRates()
    }

}
