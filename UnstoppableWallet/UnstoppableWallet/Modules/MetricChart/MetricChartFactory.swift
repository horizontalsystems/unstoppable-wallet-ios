import Foundation
import MarketKit
import LanguageKit
import CurrencyKit
import Chart

class MetricChartFactory {
    static private let noChangesLimitPercent: Decimal = 0.2

    private let timelineHelper: ITimelineHelper
    private let dateFormatter = DateFormatter()

    init(timelineHelper: ITimelineHelper, currentLocale: Locale) {
        self.timelineHelper = timelineHelper

        dateFormatter.locale = currentLocale
    }

    private func chartData(points: [MetricChartModule.Item]) -> ChartData {
        // fill items by points
        let items = points.map { (point: MetricChartModule.Item) -> ChartItem in
            let item = ChartItem(timestamp: point.timestamp)

            item.added(name: .rate, value: point.value)
            point.indicators?.forEach { key, value in
                item.added(name: key, value: value)
            }

            return item
        }

        return ChartData(items: items, startTimestamp: points.first?.timestamp ?? 0, endTimestamp: points.last?.timestamp ?? 0)
    }

    private func format(value: Decimal?, currency: Currency, valueType: MetricChartModule.ValueType, exactlyValue: Bool = false) -> String? {
        guard let value = value else {
            return nil
        }

        switch valueType {
        case .percent:         // values in percent
            return ValueFormatter.instance.format(percentValue: value, signed: false)
        case .currencyValue:
            return CurrencyCompactFormatter.instance.format(currency: currency, value: value)
        case .compactCurrencyValue:                   // others in compact forms
            if exactlyValue {
                let currencyValue = CurrencyValue(currency: currency, value: value)
                return ValueFormatter.instance.format(currencyValue: currencyValue)
            } else {
                return CurrencyCompactFormatter.instance.format(currency: currency, value: value)
            }
        }
    }

}

extension MetricChartFactory {

    func convert(items: [MetricChartModule.Item], interval: HsTimePeriod, valueType: MetricChartModule.ValueType, currency: Currency) -> MetricChartViewModel.ViewItem {
        // build data with rates
        let data = chartData(points: items)

        // calculate min and max limit texts
        let values = data.values(name: .rate)
        var min = values.min()
        var max = values.max()
        if let minValue = min, let maxValue = max, minValue == maxValue {
            min = minValue * (1 - Self.noChangesLimitPercent)
            max = maxValue * (1 + Self.noChangesLimitPercent)
        }
        let minString = format(value: min, currency: currency, valueType: valueType)
        let maxString = format(value: max, currency: currency, valueType: valueType)

        // determine chart growing state. when chart not full - it's nil
        var chartTrend: MovementTrend = .neutral

        var valueDiff: Decimal?
        var value: String?
        if let first = data.items.first(where: { ($0.indicators[.rate] ?? 0) != 0 }), let last = data.items.last, let firstValue = first.indicators[.rate], let lastValue = last.indicators[.rate] {
            value = format(value: lastValue, currency: currency, valueType: valueType)
            valueDiff = (lastValue - firstValue) / firstValue * 100
            chartTrend = (lastValue - firstValue).isSignMinus ? .down : .up
        }

        // make timeline for chart

        let gridInterval = ChartIntervalConverter.convert(interval: interval) // hours count
        let timeline = timelineHelper
                .timestamps(startTimestamp: data.startWindow, endTimestamp: data.endWindow, separateHourlyInterval: gridInterval)
                .map {
                    ChartTimelineItem(text: timelineHelper.text(timestamp: $0, separateHourlyInterval: gridInterval, dateFormatter: dateFormatter), timestamp: $0)
                }

        return MetricChartViewModel.ViewItem(chartData: data, chartTrend: chartTrend, currentValue: value, minValue: minString, maxValue: maxString, chartDiff: valueDiff, timeline: timeline)
    }

    func selectedPointViewItem(chartItem: ChartItem, valueType: MetricChartModule.ValueType, currency: Currency) -> SelectedPointViewItem? {
        guard let value = chartItem.indicators[.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)

        let formattedValue = format(value: value, currency: currency, valueType: valueType, exactlyValue: true)

        var rightSideMode: SelectedPointViewItem.RightSideMode = .none
        if let dominance = chartItem.indicators[.dominance] {
            rightSideMode = .dominance(value: dominance)
        }
        return SelectedPointViewItem(date: formattedDate, value: formattedValue, rightSideMode: rightSideMode)
    }

}
