import RxSwift

class RateManager {
    enum RateError: Error {
        case expired
    }

    private let latestRateFallbackThreshold: Double = 10 // in minutes

    private let disposeBag = DisposeBag()

    private let storage: IRateStorage
    private let apiProvider: IRateApiProvider

    init(storage: IRateStorage, apiProvider: IRateApiProvider) {
        self.storage = storage
        self.apiProvider = apiProvider
    }

    private func nonExpiredLatestRateSingle(coinCode: CoinCode, currencyCode: String, date: Date) -> Single<Decimal> {
        let referenceTimestamp = date.timeIntervalSince1970
        let currentTimestamp = Date().timeIntervalSince1970

        guard referenceTimestamp > currentTimestamp - 60 * latestRateFallbackThreshold else {
            return Single.error(RateError.expired)
        }

        return storage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                .take(1)
                .map { $0.value }
                .asSingle()
    }

}

extension RateManager: IRateManager {

    func refreshLatestRates(coinCodes: [CoinCode], currencyCode: String) {
        apiProvider.getLatestRateData(currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] latestRateData in
                    for coinCode in coinCodes {
                        guard let rateValue = latestRateData.values[coinCode] else {
                            continue
                        }

                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: rateValue, date: latestRateData.date, isLatest: true)
                        self?.storage.save(latestRate: rate)
                    }
                })
                .disposed(by: disposeBag)
    }

    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, date: Date) -> Single<Decimal> {
        return storage.timestampRateObservable(coinCode: coinCode, currencyCode: currencyCode, date: date)
                .take(1)
                .asSingle()
                .flatMap { [unowned self] rate -> Single<Decimal> in
                    if let rate = rate {
                        return Single.just(rate.value)
                    } else {
                        let apiSingle = self.apiProvider.getRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
                                .do(onSuccess: { [weak self] value in
                                    let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: value, date: date, isLatest: false)
                                    self?.storage.save(rate: rate)
                                })

                        return self.nonExpiredLatestRateSingle(coinCode: coinCode, currencyCode: currencyCode, date: date)
                                .do(onSuccess: { _ in
                                    apiSingle
                                            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                                            .subscribe()
                                            .disposed(by: self.disposeBag)
                                })
                                .catchError { _ in
                                    return apiSingle
                                }
                    }
                }
    }

    func clear() {
        storage.clearRates()
    }

}
