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
    private static let yearPointCount = 53

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

    private func convert(responseData: ChartRateData, coinCode: CoinCode, currencyCode: String, type: ChartType) -> [ChartPoint] {
        var points = chartRateConverter.convert(chartRateData: responseData)
        if let rate = rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode), rate.date.timeIntervalSince1970 > (points.last?.timestamp ?? 0) {
            points.append(ChartPoint(timestamp: rate.date.timeIntervalSince1970, value: rate.value))
        }
        if type == .year {
            return Array(points.suffix(RateStatsManager.yearPointCount))
        } else {
            return points
        }
    }

    private func calculateDiff(for data: ChartRateData) -> Decimal {
        if let first = data.values.first(where: { value in return !value.isZero }), let last = data.values.last {
            return (last - first) / first * 100
        }
        return 0
    }

}

extension RateStatsManager: IRateStatsManager {

    func rateStats(coinCode: CoinCode, currencyCode: String) -> Single<ChartData> {
        let currentTimestamp = Date().timeIntervalSince1970

        let key = StatsKey(coinCode: coinCode, currencyCode: currencyCode)

        if let chartData = stats[key], let lastDayPoint = chartData.stats[.day]?.last, currentTimestamp - lastDayPoint.timestamp < 30 * 60 { // check whether the stats exceeded half an hour threshold
            return Single.just(chartData)
        }

        return apiProvider.getRateStatsData(coinCode: coinCode, currencyCode: currencyCode)
                .map { [weak self] response -> ChartData in
                    var stats = [ChartType: [ChartPoint]]()
                    var diffs = [ChartType: Decimal]()
                    response.stats.forEach { key, value in
                        if let type = ChartType(rawValue: key) {
                            stats[type] = self?.convert(responseData: value, coinCode: coinCode, currencyCode: currencyCode, type: type) ?? []
                            diffs[type] = self?.calculateDiff(for: value)
                        }
                    }

                    return ChartData(marketCap: response.marketCap, stats: stats, diffs: diffs)
                }
                .do(onSuccess: { [weak self] chartData in
                    self?.stats[StatsKey(coinCode: coinCode, currencyCode: currencyCode)] = chartData
                })
    }

}
