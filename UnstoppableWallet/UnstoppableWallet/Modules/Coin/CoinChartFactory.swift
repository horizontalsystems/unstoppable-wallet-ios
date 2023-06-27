import Foundation
import MarketKit
import CurrencyKit
import LanguageKit
import Chart

class CoinChartFactory {
    private let dateFormatter = DateFormatter()

    init(currentLocale: Locale) {
        dateFormatter.locale = currentLocale
    }

    func convert(item: CoinChartService.Item, periodType: HsPeriodType, currency: Currency) -> ChartModule.ViewItem {
        var points = item.chartPointsItem.points
        var firstPoint = item.chartPointsItem.firstPoint
        var lastPoint = item.chartPointsItem.lastPoint

        // add current rate point, if last point older
        if item.timestamp > lastPoint.timestamp {
            let point = ChartPoint(timestamp: item.timestamp, value: item.rate)

            points.append(point)
            lastPoint = point

            // for daily chart we need change oldest visible point to 24h back timestamp-same point
            if periodType.in([.day1]), let rateDiff24 = item.rateDiff24h {
                let timestamp = item.timestamp - 24 * 60 * 60
                let value = 100 * item.rate / (100 + rateDiff24)

                let point = ChartPoint(timestamp: timestamp, value: value)

                if let index = points.firstIndex(where: { $0.timestamp > timestamp }) {
                    points.insert(point, at: index)
                    points.remove(at: index - 1)
                }

                firstPoint = point
            }
        }

        let items = points.map { point in
            let item = ChartItem(timestamp: point.timestamp).added(name: ChartData.rate, value: point.value)

            if let volume = point.volume {
                item.added(name: ChartData.volume, value: volume)
            }

            return item
        }

        let values = points.map { $0.value }

        return ChartModule.ViewItem(
                value: ValueFormatter.instance.formatFull(currencyValue: CurrencyValue(currency: currency, value: item.rate)),
                valueDescription: nil,
                rightSideMode: .none,
                chartData: ChartData(items: items, startWindow: firstPoint.timestamp, endWindow: lastPoint.timestamp),
                indicators: ChartIndicatorFactory.default, //todo:
                chartTrend: lastPoint.value > firstPoint.value ? .up : .down,
                chartDiff: (lastPoint.value - firstPoint.value) / firstPoint.value * 100,
                minValue: values.min().flatMap { ValueFormatter.instance.formatFull(currency: currency, value: $0) },
                maxValue: values.max().flatMap { ValueFormatter.instance.formatFull(currency: currency, value: $0) }
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, firstChartItem: ChartItem?, currency: Currency) -> ChartModule.SelectedPointViewItem? {
        guard let rate = chartItem.indicators[ChartData.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = ValueFormatter.instance.formatFull(currency: currency, value: rate)

        let rightSideMode: ChartModule.RightSideMode = .volume(value: chartItem.indicators[ChartData.volume].flatMap {
            $0.isZero ? nil : ValueFormatter.instance.formatShort(currency: currency, value: $0)
        })

        return ChartModule.SelectedPointViewItem(
                value: formattedValue,
                date: formattedDate,
                rightSideMode: rightSideMode
        )
    }

    static func gridInterval(fromTimestamp: TimeInterval) -> Int {
        guard let hoursCount = Calendar.current.dateComponents([.hour], from: Date(timeIntervalSince1970: fromTimestamp), to: Date()).hour else {
            return ChartIntervalConverter.convert(interval: .year1)
        }

        // try to split interval by 4 chunks
        switch hoursCount {
        case 120...Int.max: return hoursCount / 4
        case 60..<120: return 24
        case 28..<60: return 12
        default: return 4
        }
    }

}

extension HsPeriodType {

    public func `in`(_ intervals: [HsTimePeriod]) -> Bool {
        switch self {
        case .byPeriod(let interval): return intervals.contains(interval)
        case .byCustomPoints(let interval, _): return intervals.contains(interval)
        case .byStartTime: return true
        }
    }

    var gridInterval: Int {
        switch self {
        case .byPeriod(let interval):
            return ChartIntervalConverter.convert(interval: interval)
        case .byCustomPoints(let interval, _):
            return ChartIntervalConverter.convert(interval: interval)
        case .byStartTime(let startTime):
            return CoinChartFactory.gridInterval(fromTimestamp: startTime)
        }
    }

}