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
    private let rateStorage: IRateStorage
    private let chartRateConverter: IChartRateConverter
    private var stats = SynchronizedDictionary<StatsKey, ChartData>()

    init(apiProvider: IRatesStatsApiProvider, rateStorage: IRateStorage, chartRateConverter: IChartRateConverter) {
        self.apiProvider = apiProvider
        self.rateStorage = rateStorage
        self.chartRateConverter = chartRateConverter
    }

    private func convert(responseData: [String: ChartRateData], coinCode: CoinCode, currencyCode: String) -> [ChartType: [ChartPoint]] {
        var stats = [ChartType: [ChartPoint]]()
        responseData.forEach { key, value in
            if let type = ChartType(rawValue: key) {
                let points = chartRateConverter.convert(chartRateData: value)
                stats[type] = points

            if let rate = rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode), rate.date.timeIntervalSince1970 > (points.last?.timestamp ?? 0) {
                    stats[type]?.append(ChartPoint(timestamp: rate.date.timeIntervalSince1970, value: rate.value))
                }
            }
        }
        return stats
    }

}

extension RateStatsManager: IRateStatsManager {

    func rateStats(coinCode: CoinCode, currencyCode: String) -> Single<ChartData> {
        let currentTimestamp = Date().timeIntervalSince1970

        let key = StatsKey(coinCode: coinCode, currencyCode: currencyCode)

        if let chartData = stats[key], let lastDayPoint = chartData.stats[.day]?.last, currentTimestamp - lastDayPoint.timestamp > 30 * 60 { // check whether the stats exceeded half an hour threshold
            return Single.just(chartData)
        }

        return apiProvider.getRateStatsData(coinCode: coinCode, currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .map { [weak self] response -> ChartData in
                    let stats: [ChartType: [ChartPoint]] = self?.convert(responseData: response.stats, coinCode: coinCode, currencyCode: currencyCode) ?? [:]

                    return ChartData(marketCap: response.marketCap, stats: stats)
                }
                .do(onSuccess: { [weak self] chartData in
                    self?.stats[StatsKey(coinCode: coinCode, currencyCode: currencyCode)] = chartData
                })
                .observeOn(MainScheduler.instance)
    }

}
