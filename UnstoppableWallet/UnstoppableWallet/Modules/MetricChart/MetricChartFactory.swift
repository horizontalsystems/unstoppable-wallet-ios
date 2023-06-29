import Foundation
import MarketKit
import LanguageKit
import CurrencyKit
import Chart

class MetricChartFactory {
    static private let noChangesLimitPercent: Decimal = 0.2

    private let dateFormatter = DateFormatter()

    init(currentLocale: Locale) {
        dateFormatter.locale = currentLocale
    }

    private func format(value: Decimal?, valueType: MetricChartModule.ValueType, exactlyValue: Bool = false) -> String? {
        guard let value = value else {
            return nil
        }

        switch valueType {
        case .percent:
            return ValueFormatter.instance.format(percentValue: value, showSign: false)
        case .currencyValue(let currency):
            return ValueFormatter.instance.formatFull(currency: currency, value: value)
        case .counter:
            if exactlyValue {
                return value.description
            } else {
                return ValueFormatter.instance.formatShort(value: value)
            }
        case .compactCoinValue(let coin):
            let valueString: String?
            if exactlyValue {
                valueString = value.description
            } else {
                valueString = ValueFormatter.instance.formatShort(value: value)
            }
            return [valueString, coin.code].compactMap { $0 }.joined(separator: " ")
        case .compactCurrencyValue(let currency):
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

        let values = itemData.items.map { $0.value }
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
            value = format(value: lastItem.value, valueType: valueType)
            chartTrend = (lastItem.value - firstItem.value).isSignMinus ? .down : .up
            valueDiff = (lastItem.value - firstItem.value) / firstItem.value * 100

            if let first = itemData.indicators[MarketGlobalModule.dominance]?.first, let last = itemData.indicators[MarketGlobalModule.dominance]?.last {
                rightSideMode = .dominance(value: last, diff: (last - first) / first * 100)
            }
        case .aggregated(let aggregatedValue):
            value = format(value: aggregatedValue, valueType: valueType)
            chartTrend = .neutral
        }

        var chartItems = [ChartItem]()
        for index in 0..<itemData.items.count {
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
                    configuration: ChartIndicator.LineConfiguration.dominance)

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
                minValue: format(value: min, valueType: valueType),
                maxValue: format(value: max, valueType: valueType)
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, firstChartItem: ChartItem?, valueType: MetricChartModule.ValueType) -> ChartModule.SelectedPointViewItem? {
        guard let value = chartItem.indicators[ChartData.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = format(value: value, valueType: valueType)

        var rightSideMode: ChartModule.RightSideMode = .none

        if let dominance = chartItem.indicators[ChartIndicator.LineConfiguration.dominanceId] {
            rightSideMode = .dominance(value: dominance, diff: nil)
        } else if let volume = chartItem.indicators[ChartData.volume] {
            rightSideMode = .volume(value: format(value: volume, valueType: valueType))
        }

        return ChartModule.SelectedPointViewItem(
                value: formattedValue,
                date: formattedDate,
                rightSideMode: rightSideMode
        )
    }

}
