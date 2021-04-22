import Foundation
import XRatesKit
import LanguageKit
import CurrencyKit
import Chart
import CoinKit

class MarketGlobalChartFactory {
    private let timelineHelper: ITimelineHelper
    private let dateFormatter = DateFormatter()

    init(timelineHelper: ITimelineHelper, currentLocale: Locale) {
        self.timelineHelper = timelineHelper

        dateFormatter.locale = currentLocale
    }

    private func chartData(points: [GlobalCoinMarketPoint], metricsType: MarketGlobalModule.MetricsType) -> ChartData {
        // fill items by points
        let items = points.map { (point: GlobalCoinMarketPoint) -> ChartItem in
            let item = ChartItem(timestamp: point.timestamp)

            let value: Decimal
            switch metricsType {
            case .defiCap: value = point.marketCapDefi
            case .btcDominance: value = point.dominanceBtc
            case .volume24h: value = point.volume24h
            case .tvlInDefi: value = point.tvl
            }

            item.add(name: .rate, value: value)
            return item
        }

        return ChartData(items: items, startTimestamp: points.first?.timestamp ?? 0, endTimestamp: points.last?.timestamp ?? 0)
    }

    private func format(value: Decimal?, currency: Currency, metricsType: MarketGlobalModule.MetricsType, compact: Bool = true) -> String? {
        guard let value = value else {
            return nil
        }

        switch metricsType {
        case .btcDominance:         // values in percent
            return ValueFormatter.instance.format(percentValue: value, signed: false)
        default:                   // others in compact forms
            if compact {
                return CurrencyCompactFormatter.instance.format(currency: currency, value: value)
            } else {
                let currencyValue = CurrencyValue(currency: currency, value: value)
                return ValueFormatter.instance.format(currencyValue: currencyValue)
            }
        }
    }

}

extension MarketGlobalChartFactory {

    func convert(items: [GlobalCoinMarketPoint], chartType: ChartType, metricsType: MarketGlobalModule.MetricsType, currency: Currency) -> MarketGlobalChartViewModel.ViewItem {
        // build data with rates
        let data = chartData(points: items, metricsType: metricsType)

        // calculate min and max limit texts
        let values = data.values(name: .rate)
        let min = format(value: values.min(), currency: currency, metricsType: metricsType)
        let max = format(value: values.max(), currency: currency, metricsType: metricsType)

        // determine chart growing state. when chart not full - it's nil
        var chartTrend: MovementTrend = .neutral

        var valueDiff: Decimal?
        var value: String?
        if let first = data.items.first(where: { ($0.indicators[.rate] ?? 0) != 0 }), let last = data.items.last, let firstValue = first.indicators[.rate], let lastValue = last.indicators[.rate] {
            value = format(value: lastValue, currency: currency, metricsType: metricsType)
            valueDiff = (lastValue - firstValue) / firstValue * 100
            chartTrend = (lastValue - firstValue).isSignMinus ? .down : .up
        }

        // make timeline for chart

        let gridInterval = ChartTypeIntervalConverter.convert(chartType: chartType) // hours count
        let timeline = timelineHelper
                .timestamps(startTimestamp: data.startWindow, endTimestamp: data.endWindow, separateHourlyInterval: gridInterval)
                .map {
                    ChartTimelineItem(text: timelineHelper.text(timestamp: $0, separateHourlyInterval: gridInterval, dateFormatter: dateFormatter), timestamp: $0)
                }

        return MarketGlobalChartViewModel.ViewItem(chartData: data, chartTrend: chartTrend, currentValue: value, minValue: min, maxValue: max, chartDiff: valueDiff, timeline: timeline)
    }

    func selectedPointViewItem(chartItem: ChartItem, type: ChartType, metricsType: MarketGlobalModule.MetricsType, currency: Currency) -> SelectedPointViewItem? {
        guard let value = chartItem.indicators[.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)

        let formattedValue = format(value: value, currency: currency, metricsType: metricsType, compact: false)

        return SelectedPointViewItem(date: formattedDate, value: formattedValue, rightSideMode: .none)
    }

}
