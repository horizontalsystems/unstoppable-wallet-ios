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

    private func chartData(items: [MetricChartModule.Item]) -> ChartData {
        // fill items by points
        let items = items.map { (point: MetricChartModule.Item) -> ChartItem in
            let item = ChartItem(timestamp: point.timestamp)

            item.added(name: .rate, value: point.value)
            point.indicators?.forEach { key, value in
                item.added(name: key, value: value)
            }

            return item
        }

        return ChartData(items: items, startTimestamp: items.first?.timestamp ?? 0, endTimestamp: items.last?.timestamp ?? 0)
    }

    private func format(value: Decimal?, valueType: MetricChartModule.ValueType, exactlyValue: Bool = false) -> String? {
        guard let value = value else {
            return nil
        }

        switch valueType {
        case .percent:         // values in percent
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
        case .compactCurrencyValue(let currency):                   // others in compact forms
            if exactlyValue {
                return ValueFormatter.instance.formatFull(currency: currency, value: value)
            } else {
                return ValueFormatter.instance.formatShort(currency: currency, value: value)
            }
        }
    }

}

extension MetricChartFactory {

    func convert(itemData: MetricChartModule.ItemData, interval: HsTimePeriod, valueType: MetricChartModule.ValueType) -> ChartModule.ViewItem {
        // build data with rates
        let data = chartData(items: itemData.items)

        // calculate min and max limit texts
        let values = data.values(name: .rate)
        var min = values.min()
        var max = values.max()
        if let minValue = min, let maxValue = max, minValue == maxValue {
            min = minValue * (1 - Self.noChangesLimitPercent)
            max = maxValue * (1 + Self.noChangesLimitPercent)
        }
        let minString = format(value: min, valueType: valueType)
        let maxString = format(value: max, valueType: valueType)

        // determine chart growing state. when chart not full - it's nil
        var chartTrend: MovementTrend = .neutral

        var valueDiff: Decimal?
        var value: String?
        var rightSideMode: ChartModule.RightSideMode = .none

        switch itemData.type {
        case .regular:
            if let first = data.items.first(where: { ($0.indicators[.rate] ?? 0) != 0 }), let last = data.items.last, let firstValue = first.indicators[.rate], let lastValue = last.indicators[.rate] {
                value = format(value: lastValue, valueType: valueType)
                chartTrend = (lastValue - firstValue).isSignMinus ? .down : .up
                valueDiff = (lastValue - firstValue) / firstValue * 100
            }

            if let first = data.items.first?.indicators[.dominance], let last = data.items.last?.indicators[.dominance] {
                rightSideMode = .dominance(value: last, diff: (last - first) / first * 100)
            }
        case .aggregated(let aggregatedValue):
            value = format(value: aggregatedValue, valueType: valueType)
            chartTrend = .ignore
        }

        return ChartModule.ViewItem(
                value: value,
                rightSideMode: rightSideMode,
                chartData: data,
                chartTrend: chartTrend,
                chartDiff: valueDiff,
                minValue: minString,
                maxValue: maxString
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, firstChartItem: ChartItem?, valueType: MetricChartModule.ValueType) -> ChartModule.SelectedPointViewItem? {
        guard let value = chartItem.indicators[.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = format(value: value, valueType: valueType)

        var rightSideMode: ChartModule.RightSideMode = .none

        if let dominance = chartItem.indicators[.dominance] {
            rightSideMode = .dominance(value: dominance, diff: nil)
        } else if let volume = chartItem.indicators[.volume] {
            rightSideMode = .volume(value: format(value: volume, valueType: valueType))
        }

        return ChartModule.SelectedPointViewItem(
                value: formattedValue,
                diff: nil,
                date: formattedDate,
                rightSideMode: rightSideMode
        )
    }

}
