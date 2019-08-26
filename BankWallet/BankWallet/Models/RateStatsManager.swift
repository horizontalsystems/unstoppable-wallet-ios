import RxSwift

struct StatsKey: Hashable {
    let coinCode: CoinCode
    let currencyCode: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
    }
}

class RateStatsManager {
    private let disposeBag = DisposeBag()
    private let apiProvider: IRatesStatsApiProvider
    private var stats = SynchronizedDictionary<StatsKey, RateStatsData>()

    init(apiProvider: IRatesStatsApiProvider) {
        self.apiProvider = apiProvider
    }

}

extension RateStatsManager: IRateStatsManager {

    func refreshLatestRateStats(coinCode: CoinCode, currencyCode: String) {
        apiProvider.getRateStatsData(coinCode: coinCode, currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] latestRateData in
                    self?.stats[StatsKey(coinCode: coinCode, currencyCode: currencyCode)] = latestRateData
                })
                .disposed(by: disposeBag)
    }

    func rateStats(coinCode: CoinCode, currencyCode: String) -> Single<RateStatsData> {
        let key = StatsKey(coinCode: coinCode, currencyCode: currencyCode)
        if let statsData = stats[key] {
            return Single.just(statsData)
        }

        return apiProvider.getRateStatsData(coinCode: coinCode, currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .do(onSuccess: { [weak self] latestRateData in
                    self?.stats[StatsKey(coinCode: coinCode, currencyCode: currencyCode)] = latestRateData
                })
    }

}
