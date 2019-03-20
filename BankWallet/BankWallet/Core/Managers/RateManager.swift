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

    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Decimal> {
        return storage.timestampRateObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                .take(1)
                .flatMap { [weak self] rate -> Observable<Decimal> in
                    if let rate = rate {
                        return Observable.just(rate.value)
                    } else {
                        let date = Date(timeIntervalSince1970: timestamp)

                        let networkObservable = self?.networkManager.getRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
                                .do(onNext: { [weak self] value in
                                    let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: value, timestamp: timestamp, isLatest: false)
                                    self?.storage.save(rate: rate)
                                }) ?? Observable.empty()

                        return networkObservable.catchError { _ in
                            return self?.latestRateFallbackObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp) ?? Observable.empty()
                        }
                    }
                }
    }

    func clear() {
        storage.clearRates()
    }

}
