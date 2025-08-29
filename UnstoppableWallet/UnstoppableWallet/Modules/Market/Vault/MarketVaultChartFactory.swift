import Chart
import Foundation
import MarketKit

class MarketVaultChartFactory {
    private static let noChangesLimitPercent: Decimal = 0.2

    private let dateFormatter = DateFormatter()
    private let currencyManager = Core.shared.currencyManager

    init(currentLocale: Locale) {
        dateFormatter.locale = currentLocale
    }
}

extension MarketVaultChartFactory: IMetricChartFactory {
    func convert(itemData: MetricChartModule.ItemData, valueType: MetricChartModule.ValueType) -> ChartModule.ViewItem? {
        guard let firstItem = itemData.items.first, let lastItem = itemData.items.last else {
            return nil
        }

        let startTimestamp: TimeInterval
        let endTimestamp: TimeInterval

        if itemData.items.count == 1 {
            startTimestamp = firstItem.timestamp - 3600
            endTimestamp = firstItem.timestamp + 3600
        } else {
            startTimestamp = firstItem.timestamp
            endTimestamp = lastItem.timestamp
        }

        var value: String?
        var valueDiff: ValueDiff?

        value = MetricChartFactory.format(value: lastItem.value, valueType: valueType).map {
            ["market.vault.apy".localized, $0].joined(separator: " ")
        }
        let diff = lastItem.value - firstItem.value
        let trend: MovementTrend = firstItem.value <= lastItem.value ? .up : .down

        let valueString = ValueFormatter.instance.format(percentValue: diff, signType: .always)
        valueDiff = valueString.map { ValueDiff(value: $0, trend: trend) }

        var chartItems = [ChartItem]()
        for index in 0 ..< itemData.items.count {
            let chartItem = ChartItem(timestamp: itemData.items[index].timestamp)
            chartItem.added(name: ChartData.rate, value: itemData.items[index].value)
            if let value = itemData.indicators[ChartData.volume]?.at(index: index) {
                chartItem.added(name: ChartData.volume, value: value)
            }
            chartItems.append(chartItem)
        }

        return ChartModule.ViewItem(
            value: value,
            valueDescription: nil,
            rightSideMode: .none,
            chartData: ChartData(items: chartItems, startWindow: startTimestamp, endWindow: endTimestamp),
            indicators: [],
            chartTrend: trend,
            chartDiff: valueDiff,
            limitFormatter: { value in MetricChartFactory.format(value: value, valueType: valueType) }
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, firstChartItem _: ChartItem?, valueType _: MetricChartModule.ValueType) -> ChartModule.SelectedPointViewItem? {
        guard let value = chartItem.indicators[ChartData.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)

        var rightSideMode: ChartModule.RightSideMode = .none

        if let volume = chartItem.indicators[ChartData.volume] {
            rightSideMode = .custom(title: "market.global.tvl".localized, value: MetricChartFactory.format(value: volume, valueType: .compactCurrencyValue(currencyManager.baseCurrency)))
        }

        let formattedValue = MetricChartFactory.format(value: value, valueType: .percent)

        return ChartModule.SelectedPointViewItem(
            value: formattedValue,
            date: formattedDate,
            rightSideMode: rightSideMode
        )
    }
}
