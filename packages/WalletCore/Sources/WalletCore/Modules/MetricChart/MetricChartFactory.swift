import Chart
import Foundation
import MarketKit

protocol IMetricChartFactory {
    func convert(itemData: MetricChartModule.ItemData, valueType: MetricChartModule.ValueType) -> ChartModule.ViewItem?
    func selectedPointViewItem(chartItem: ChartItem, firstChartItem _: ChartItem?, valueType: MetricChartModule.ValueType) -> ChartModule.SelectedPointViewItem?
}

class MetricChartFactory {
    private static let noChangesLimitPercent: Decimal = 0.2

    private let dateFormatter = DateFormatter()
    private let currencyManager = Core.shared.currencyManager
    private let hardcodedRightMode: String?

    init(currentLocale: Locale, hardcodedRightMode: String? = nil) {
        dateFormatter.locale = currentLocale
        self.hardcodedRightMode = hardcodedRightMode
    }

    static func format(value: Decimal?, valueType: MetricChartModule.ValueType, exactlyValue: Bool = false) -> String? {
        guard let value else {
            return nil
        }

        switch valueType {
        case .percent:
            return ValueFormatter.instance.format(percentValue: value, signType: .never)
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
                return ValueFormatter.instance.formatFull(currency: currency, value: value, signType: .always)
            } else {
                return ValueFormatter.instance.formatShort(currency: currency, value: value, signType: .auto)
            }
        }
    }
}

extension MetricChartFactory: IMetricChartFactory {
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

        let chartTrend: MovementTrend
        var value: String?
        var valueDiff: ValueDiff?
        var rightSideMode: ChartModule.RightSideMode = .none

        switch itemData.type {
        case .regular:
            value = Self.format(value: lastItem.value, valueType: valueType)
            let diff = (lastItem.value - firstItem.value) / firstItem.value * 100
            chartTrend = diff.isSignMinus ? .down : .up

            let valueString = ValueFormatter.instance.format(percentValue: diff, signType: .always)
            valueDiff = valueString.map { ValueDiff(value: $0, trend: chartTrend) }

            if let hardcodedRightMode {
                rightSideMode = .custom(title: hardcodedRightMode, value: nil)
            } else if let first = itemData.indicators[MarketGlobalModule.dominance]?.first, let last = itemData.indicators[MarketGlobalModule.dominance]?.last {
                rightSideMode = .dominance(value: last, diff: (last - first) / first * 100)
            }
        case .etf:
            if let last = itemData.indicators[MarketGlobalModule.totalAssets]?.last { // etf chart
                value = ValueFormatter.instance.formatShort(currency: currencyManager.baseCurrency, value: last)
            }
            if let last = itemData.indicators[MarketGlobalModule.dailyInflow]?.last { // etf chart
                let diffString = ValueFormatter.instance.formatShort(currency: currencyManager.baseCurrency, value: last, signType: .always)
                valueDiff = diffString.map { ValueDiff(value: $0, trend: lastItem.value.isSignMinus ? .down : .up) }
            }

            chartTrend = .neutral

            rightSideMode = .none
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
        if let totalAssets = itemData.indicators[MarketGlobalModule.totalAssets] {
            let totalIndicator = PrecalculatedIndicator(
                id: MarketGlobalModule.totalAssets,
                enabled: true,
                values: totalAssets,
                configuration: ChartIndicator.LineConfiguration.totalAssets
            )
            indicators.append(totalIndicator)
        }
        if let dailyInflow = itemData.indicators[MarketGlobalModule.dailyInflow] {
            let totalIndicator = PrecalculatedIndicator(
                id: MarketGlobalModule.dailyInflow,
                enabled: false,
                values: dailyInflow,
                configuration: ChartIndicator.LineConfiguration.dailyInflow
            )
            indicators.append(totalIndicator)
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

        var rightSideMode: ChartModule.RightSideMode = .none

        if let dominance = chartItem.indicators[ChartIndicator.LineConfiguration.dominanceId] {
            rightSideMode = .dominance(value: dominance, diff: nil)
        } else if let volume = chartItem.indicators[ChartData.volume] {
            rightSideMode = .volume(value: Self.format(value: volume, valueType: valueType))
        }

        // if etf chart
        if let totalAsset = chartItem.indicators[ChartIndicator.LineConfiguration.totalAssetId] {
            let formattedValue = ValueFormatter.instance.formatShort(currency: currencyManager.baseCurrency, value: totalAsset)

            let dailyInflow = chartItem.indicators[ChartIndicator.LineConfiguration.dailyInflowId]
            let diffString = dailyInflow.flatMap { ValueFormatter.instance.formatShort(currency: currencyManager.baseCurrency, value: $0, signType: .always) }
            let diff = diffString.map { ValueDiff(value: $0, trend: value.isSignMinus ? .down : .up) }

            return ChartModule.SelectedPointViewItem(
                value: formattedValue,
                diff: diff,
                date: formattedDate,
                rightSideMode: rightSideMode
            )
        }

        let formattedValue = Self.format(value: value, valueType: valueType)

        return ChartModule.SelectedPointViewItem(
            value: formattedValue,
            date: formattedDate,
            rightSideMode: rightSideMode
        )
    }
}
