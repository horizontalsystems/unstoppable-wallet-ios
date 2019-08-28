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

    init() {
    }

    func chartViewItem(type: ChartType, chartData: ChartData, rate: Rate?, currency: Currency) throws -> ChartViewItem {
        guard var points = chartData.stats[type] else {
            throw FactoryError.noRateStats
        }

        if type == .year {
            points = Array(points.suffix(ChartRateFactory.yearPointCount))
        }

        var marketCapValue: CurrencyValue? = nil
        if let marketCap = chartData.marketCap {
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

        var rateValue: CurrencyValue? = nil
        if let rate = rate, !rate.expired {
            rateValue = CurrencyValue(currency: currency, value: rate.value)
        }
        return ChartViewItem(type: type, rateValue: rateValue, marketCapValue: marketCapValue, lowValue: lowValue, highValue: highValue, diff: diff, points: points)
    }

}
