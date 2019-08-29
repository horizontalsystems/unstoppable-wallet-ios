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
    enum FactoryError: Error {
        case noRateStats
        case noPercentDelta
    }

    init() {
    }

    func chartViewItem(type: ChartType, chartData: ChartData, rate: Rate?, currency: Currency) throws -> ChartViewItem {
        guard let points = chartData.stats[type] else {
            throw FactoryError.noRateStats
        }
        guard let diff = chartData.diffs[type] else {
            throw FactoryError.noPercentDelta
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

        var rateValue: CurrencyValue? = nil
        if let rate = rate, !rate.expired {
            rateValue = CurrencyValue(currency: currency, value: rate.value)
        }
        return ChartViewItem(type: type, rateValue: rateValue, marketCapValue: marketCapValue, lowValue: lowValue, highValue: highValue, diff: diff, points: points)
    }

}
