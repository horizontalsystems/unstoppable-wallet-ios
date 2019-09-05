import RxSwift

class RateManager {
    enum RateError: Error {
        case expired
    }

    private let disposeBag = DisposeBag()

    private let storage: IRateStorage
    private let apiProvider: IRateApiProvider
    private let walletManager: IWalletManager
    private let reachabilityManager: IReachabilityManager
    private let currencyManager: ICurrencyManager

    init(storage: IRateStorage, apiProvider: IRateApiProvider, walletManager: IWalletManager, reachabilityManager: IReachabilityManager, currencyManager: ICurrencyManager) {
        self.storage = storage
        self.apiProvider = apiProvider
        self.walletManager = walletManager
        self.reachabilityManager = reachabilityManager
        self.currencyManager = currencyManager
    }

    private func nonExpiredLatestRateSingle(coinCode: CoinCode, currencyCode: String, date: Date) -> Single<Decimal> {
        let referenceTimestamp = date.timeIntervalSince1970
        let currentTimestamp = Date().timeIntervalSince1970

        guard referenceTimestamp > currentTimestamp - Rate.latestRateFallbackThreshold else {
            return Single.error(RateError.expired)
        }

        return storage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                .take(1)
                .map { $0.value }
                .asSingle()
    }

    private func refreshLatestRates(coinCodes: [CoinCode], currencyCode: String) {
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

}

extension RateManager: IRateManager {

    func nonExpiredLatestRate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return storage.latestRate(coinCode: coinCode, currencyCode: currencyCode).flatMap { rate in
            rate.expired ? nil : rate
        }
    }

    func syncLatestRates() {
        guard reachabilityManager.isReachable else {
            return
        }

        var coinCodes = Set<CoinCode>()
        for wallet in walletManager.wallets {
            coinCodes.insert(wallet.coin.code)
        }

        guard coinCodes.count > 0 else {
            return
        }

        refreshLatestRates(coinCodes: Array(coinCodes), currencyCode: currencyManager.baseCurrency.code)
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
