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

    private func chartData(points: [ChartPoint], startTimestamp: TimeInterval, endTimestamp: TimeInterval) -> ChartData {
        // fill items by points
        let items = points.map { (point: ChartPoint) -> ChartItem in
            let item = ChartItem(timestamp: point.timestamp)

            item.added(name: .rate, value: point.value)
            if let volume = point.extra[ChartPoint.volume] {
                item.added(name: .volume, value: volume)
            }

            return item
        }

        return ChartData(items: items, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
    }

    private func chartItem(point: ChartPoint) -> ChartItem {
        let chartItem = ChartItem(timestamp: point.timestamp)
        chartItem.added(name: .rate, value: point.value)
        return chartItem
    }

    private func calculateTrend(down: Decimal?, up: Decimal?) -> MovementTrend {
        guard let down = down, let up = up else {
            return .neutral
        }

        if up > down {
            return .up
        } else if up < down {
            return .down
        }
        return .neutral
    }

    private func calculateRsiTrend(rsi: Decimal?) -> MovementTrend {
        guard let rsi = rsi else {
            return .neutral
        }

        if rsi > 70 {
            return .down
        } else if rsi < 30 {
            return .up
        }
        return .neutral
    }

    func convert(item: CoinChartService.Item, periodType: HsPeriodType, currency: Currency) -> ChartModule.ViewItem {
        var points = item.chartInfo.points
        var endTimestamp = item.chartInfo.endTimestamp

        var extendedPoint: ChartPoint?

        if let lastPointTimestamp = item.chartInfo.points.last?.timestamp,
           let timestamp = item.timestamp,
           let rate = item.rate,
           timestamp > lastPointTimestamp {
            // add current rate in data
            endTimestamp = max(timestamp, endTimestamp)
            points.append(ChartPoint(timestamp: timestamp, value: rate))

            // create extended point for 24h ago
            if periodType == .day1, let rateDiff24 = item.rateDiff24h {
                let firstTimestamp = timestamp - 24 * 60 * 60
                let price24h = 100 * rate / (100 + rateDiff24)
                extendedPoint = ChartPoint(timestamp: firstTimestamp, value: price24h)
            }
        }
        // build data with rates, volumes and indicators for points
        let data = chartData(points: points, startTimestamp: item.chartInfo.startTimestamp, endTimestamp: endTimestamp)

        // calculate item for 24h back point and add to data
        if let extendedPoint = extendedPoint {
            let extendedItem = chartItem(point: extendedPoint)

            data.insert(item: extendedItem)
            // change start visible timestamp
            data.startWindow = extendedItem.timestamp
        }

        // remove non-visible items
        data.items = data.items.filter { item in item.timestamp >= data.startWindow }

        // calculate min and max limit texts
        let rates = data.values(name: .rate)
        let minRate = rates.min()
        let maxRate = rates.max()

        // determine chart growing state. when chart not full - it's nil
        var chartTrend: MovementTrend = .neutral
        var chartDiff: Decimal?
        if let first = data.items.first(where: { ($0.indicators[.rate] ?? 0) != 0 }), let last = data.items.last, !item.chartInfo.expired, let firstRate = first.indicators[.rate], let lastRate = last.indicators[.rate] {
            chartDiff = (lastRate - firstRate) / firstRate * 100
            chartTrend = (lastRate - firstRate).isSignMinus ? .down : .up
        }

        var minRateString: String?, maxRateString: String?

        if let minRate = minRate, let maxRate = maxRate {
            minRateString = ValueFormatter.instance.formatFull(currency: currency, value: minRate)
            maxRateString = ValueFormatter.instance.formatFull(currency: currency, value: maxRate)
        }

        return ChartModule.ViewItem(
                value: item.rate.flatMap { ValueFormatter.instance.formatFull(currencyValue: CurrencyValue(currency: currency, value: $0)) },
                rightSideMode: .none,
                chartData: data,
                chartTrend: chartTrend,
                chartDiff: chartDiff,
                minValue: minRateString,
                maxValue: maxRateString
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, firstChartItem: ChartItem?, currency: Currency) -> ChartModule.SelectedPointViewItem? {
        guard let rate = chartItem.indicators[.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = ValueFormatter.instance.formatFull(currency: currency, value: rate)

        var diff: Decimal?

        if let firstChartItem, let firstRate = firstChartItem.indicators[.rate] {
            diff = (rate - firstRate) / firstRate * 100
        }

        let rightSideMode: ChartModule.RightSideMode = .volume(value: chartItem.indicators[.volume].flatMap {
            $0.isZero ? nil : ValueFormatter.instance.formatShort(currency: currency, value: $0)
        })

        return ChartModule.SelectedPointViewItem(
                value: formattedValue,
                diff: diff,
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
        case .byStartTime: return true
        }
    }

    var gridInterval: Int {
        switch self {
        case .byPeriod(let interval):
            return ChartIntervalConverter.convert(interval: interval)
        case .byStartTime(let startTime):
            return CoinChartFactory.gridInterval(fromTimestamp: startTime)
        }
    }

}