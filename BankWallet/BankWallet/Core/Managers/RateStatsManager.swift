import RxSwift

struct StatsCacheKey: Hashable {
    let coinCode: CoinCode
    let currencyCode: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
    }
}

struct StatsCacheData {
    var marketCap: Decimal?
    var stats: [ChartType: [ChartPoint]]
}

class RateStatsManager {
    private static let yearPointCount = 53

    private let disposeBag = DisposeBag()
    private let apiProvider: IRatesStatsApiProvider
    private let rateStorage: IRateStorage
    private let chartRateConverter: IChartRateConverter
    private var cache = SynchronizedDictionary<StatsCacheKey, StatsCacheData>()

    init(apiProvider: IRatesStatsApiProvider, rateStorage: IRateStorage, chartRateConverter: IChartRateConverter) {
        self.apiProvider = apiProvider
        self.rateStorage = rateStorage
        self.chartRateConverter = chartRateConverter
    }

    private func convert(responseData: ChartRateData, coinCode: CoinCode, currencyCode: String, type: ChartType) -> [ChartPoint] {
        let points = chartRateConverter.convert(chartRateData: responseData)
        if type == .year {
            return Array(points.suffix(RateStatsManager.yearPointCount))
        } else {
            return points
        }
    }

    private func calculateDiff(for points: [ChartPoint]) -> Decimal {
        if let first = points.first(where: { point in return !point.value.isZero }), let last = points.last {
            return (last.value - first.value) / first.value * 100
        }
        return 0
    }

    private func requestPoints(for coinCode: CoinCode, currencyCode: String) -> Single<StatsCacheData> {
        return apiProvider.getRateStatsData(coinCode: coinCode, currencyCode: currencyCode)
                .map { [weak self] response -> StatsCacheData in
                    var stats = [ChartType: [ChartPoint]]()
                    response.stats.forEach { key, value in
                        if let type = ChartType(rawValue: key) {
                            let points = self?.convert(responseData: value, coinCode: coinCode, currencyCode: currencyCode, type: type) ?? []

                            stats[type] = points
                        }
                    }

                    return StatsCacheData(marketCap: response.marketCap, stats: stats)
                }
                .do(onSuccess: { [weak self] cacheData in
                    self?.cache[StatsCacheKey(coinCode: coinCode, currencyCode: currencyCode)] = cacheData
                })
    }

}

extension RateStatsManager: IRateStatsManager {

    func rateStats(coinCode: CoinCode, currencyCode: String) -> Single<ChartData> {
        let currentTimestamp = Date().timeIntervalSince1970

        let key = StatsCacheKey(coinCode: coinCode, currencyCode: currencyCode)

        var dataRequest: Single<StatsCacheData>
        if let cacheData = cache[key], let lastDayPoint = cacheData.stats[.day]?.last, currentTimestamp - lastDayPoint.timestamp < 30 * 60 { // check whether the stats exceeded half an hour threshold
            dataRequest = Single.just(cacheData)
        } else {
            dataRequest = requestPoints(for: coinCode, currencyCode: currencyCode)
        }
        let rate = rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode)

        return dataRequest
                .map { cacheData -> ChartData in
                    var stats = [ChartType: [ChartPoint]]()
                    var diffs = [ChartType: Decimal]()
                    cacheData.stats.forEach { [weak self] type, points in
                        var points = points
                        if let rate = rate, rate.date.timeIntervalSince1970 > (points.last?.timestamp ?? 0) {
                            points.append(ChartPoint(timestamp: rate.date.timeIntervalSince1970, value: rate.value))
                        }

                        stats[type] = points
                        diffs[type] = self?.calculateDiff(for: points)
                    }

                    return ChartData(marketCap: cacheData.marketCap, stats: stats, diffs: diffs)
                }
    }

}
