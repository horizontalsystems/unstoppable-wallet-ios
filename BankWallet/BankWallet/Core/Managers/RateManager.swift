import RxSwift

class RateManager {
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

    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Double> {
        return storage.timestampRateObservable(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                .flatMap { [weak self] rate -> Observable<Double> in
                    if let rate = rate {
                        if rate.value != 0 {
                            return Observable.just(rate.value)
                        }
                    } else {
                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: 0, timestamp: timestamp, isLatest: false)
                        self?.storage.save(rate: rate)

                        self?.sync(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                    }

                    return Observable.empty()
                }
    }

}
