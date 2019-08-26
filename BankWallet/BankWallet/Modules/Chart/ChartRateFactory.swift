import Foundation

struct ChartViewItem {
    let type: ChartType

    let rateValue: CurrencyValue?
    let marketCapValue: CurrencyValue?
    let lowValue: CurrencyValue
    let highValue: CurrencyValue

    let diff: Decimal

    let points: [ChartPoint]
}

class ChartRateFactory: IChartRateFactory {
    private static let yearPointCount = 53

    enum FactoryError: Error {
        case noRateStats
    }

    private let chartRateConverter: IChartRateConverter

    init(chartRateConverter: IChartRateConverter) {
        self.chartRateConverter = chartRateConverter
    }

    func chartViewItem(type: ChartType, rateStatsData: RateStatsData, rate: Rate?, currency: Currency) throws -> ChartViewItem {
        guard let chartData = rateStatsData.stats[type.rawValue] else {
            throw FactoryError.noRateStats
        }

        var points = chartRateConverter.convert(chartRateData: chartData)
        if type == .year {
            points = Array(points.suffix(ChartRateFactory.yearPointCount))
        }
        var rateValue: CurrencyValue? = nil
        if let rate = rate {
            points.append(ChartPoint(timestamp: rate.date.timeIntervalSince1970, value: rate.value))
            rateValue = CurrencyValue(currency: currency, value: rate.value)
        }

        var marketCapValue: CurrencyValue? = nil
        if let marketCap = rateStatsData.marketCap {
            marketCapValue = CurrencyValue(currency: currency, value: marketCap)
        }
        var minimumValue = Decimal.greatestFiniteMagnitude
        var maximumValue = Decimal.zero
        points.forEach { point in
            minimumValue = min(minimumValue, point.value)
            maximumValue = max(maximumValue, point.value)
        }

        let lowValue = CurrencyValue(currency: currency, value: minimumValue)
        let highValue = CurrencyValue(currency: currency, value: maximumValue)

        var diff: Decimal = 0
        if let first = points.first(where: { point in return !point.value.isZero })?.value,
           let last = points.last?.value {
            diff = (last - first) / first * 100
        }

        return ChartViewItem(type: type, rateValue: rateValue, marketCapValue: marketCapValue, lowValue: lowValue, highValue: highValue, diff: diff, points: points)
    }

}
