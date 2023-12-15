import Chart
import Foundation
import MarketKit

class MetricChartFactory {
    private static let noChangesLimitPercent: Decimal = 0.2

    private let dateFormatter = DateFormatter()

    init(currentLocale: Locale) {
        dateFormatter.locale = currentLocale
    }

    private static func format(value: Decimal?, valueType: MetricChartModule.ValueType, exactlyValue: Bool = false) -> String? {
        guard let value else {
            return nil
        }

        switch valueType {
        case .percent:
            return ValueFormatter.instance.format(percentValue: value, showSign: false)
        case let .currencyValue(currency):
            return ValueFormatter.instance.formatFull(currency: currency, value: value)
        case .counter:
            if exactlyValue {
                return value.description
            } else {
                return ValueFormatter.instance.formatShort(value: value)
            }
        case let .compactCoinValue(coin):
            let valueString: String?
            if exactlyValue {
                valueString = value.description
            } else {
                valueString = ValueFormatter.instance.formatShort(value: value)
            }
            return [valueString, coin.code].compactMap { $0 }.joined(separator: " ")
        case let .compactCurrencyValue(currency):
            if exactlyValue {
                return ValueFormatter.instance.formatFull(currency: currency, value: value)
            } else {
                return ValueFormatter.instance.formatShort(currency: currency, value: value)
            }
        }
    }
}

extension MetricChartFactory {
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

        let values = itemData.items.map(\.value)
        var min = values.min()
        var max = values.max()

        if let minValue = min, let maxValue = max, minValue == maxValue {
            min = minValue * (1 - Self.noChangesLimitPercent)
            max = maxValue * (1 + Self.noChangesLimitPercent)
        }

        let chartTrend: MovementTrend
        var value: String?
        var valueDiff: Decimal?
        var rightSideMode: ChartModule.RightSideMode = .none

        switch itemData.type {
        case .regular:
            value = Self.format(value: lastItem.value, valueType: valueType)
            chartTrend = (lastItem.value - firstItem.value).isSignMinus ? .down : .up
            valueDiff = (lastItem.value - firstItem.value) / firstItem.value * 100

            if let first = itemData.indicators[MarketGlobalModule.dominance]?.first, let last = itemData.indicators[MarketGlobalModule.dominance]?.last {
                rightSideMode = .dominance(value: last, diff: (last - first) / first * 100)
            }
        case let .aggregated(aggregatedValue):
            value = Self.format(value: aggregatedValue, valueType: valueType)
            chartTrend = .neutral
        }

        var chartItems = [ChartItem]()
        for index in 0 ..< itemData.items.count {
            let chartItem = ChartItem(timestamp: itemData.items[index].timestamp)
            chartItem.added(name: ChartData.rate, value: itemData.items[index].value)
            if let value = itemData.indicators[ChartData.volume]?.at(index: index) {
                chartItem.added(name: ChartData.volume, value: value)
            }
            chartItems.append(chartItem)
        }

        var indicators = [ChartIndicator]()
        if let dominancePoints = itemData.indicators[MarketGlobalModule.dominance] {
            let dominanceIndicator = PrecalculatedIndicator(
                id: MarketGlobalModule.dominance,
                enabled: true,
                values: dominancePoints,
                configuration: ChartIndicator.LineConfiguration.dominance
            )

            indicators.append(dominanceIndicator)
        }

        return ChartModule.ViewItem(
            value: value,
            valueDescription: nil,
            rightSideMode: rightSideMode,
            chartData: ChartData(items: chartItems, startWindow: startTimestamp, endWindow: endTimestamp),
            indicators: indicators,
            chartTrend: chartTrend,
            chartDiff: valueDiff,
            limitFormatter: { value in Self.format(value: value, valueType: valueType) }
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, firstChartItem _: ChartItem?, valueType: MetricChartModule.ValueType) -> ChartModule.SelectedPointViewItem? {
        guard let value = chartItem.indicators[ChartData.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = Self.format(value: value, valueType: valueType)

        var rightSideMode: ChartModule.RightSideMode = .none

        if let dominance = chartItem.indicators[ChartIndicator.LineConfiguration.dominanceId] {
            rightSideMode = .dominance(value: dominance, diff: nil)
        } else if let volume = chartItem.indicators[ChartData.volume] {
            rightSideMode = .volume(value: Self.format(value: volume, valueType: valueType))
        }

        return ChartModule.SelectedPointViewItem(
            value: formattedValue,
            date: formattedDate,
            rightSideMode: rightSideMode
        )
    }
}
