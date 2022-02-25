import Foundation
import MarketKit
import CurrencyKit
import LanguageKit
import Chart

class CoinChartFactory {
    private let timelineHelper: ITimelineHelper
    private let indicatorFactory: IIndicatorFactory
    private let dateFormatter = DateFormatter()

    init(timelineHelper: ITimelineHelper, indicatorFactory: IIndicatorFactory, currentLocale: Locale) {
        self.timelineHelper = timelineHelper
        self.indicatorFactory = indicatorFactory

        dateFormatter.locale = currentLocale
    }

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let macdFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private func roundedFormat(coinCode: String, value: Decimal?) -> String {
        guard let value = value, !value.isZero, let formattedValue = coinFormatter.string(from: value as NSNumber) else {
            return "n/a".localized
        }

        return "\(formattedValue) \(coinCode)"
    }

    private func macdFormat(value: Decimal?) -> String? {
        guard let value = value, let formattedValue = macdFormatter.string(from: abs(value) as NSNumber) else {
            return nil
        }

        let sign = value.isSignMinus ? "- " : ""
        return "\(sign)\(formattedValue)"
    }

    private func scale(min: Decimal, max: Decimal) -> Int {
        let maxIntegerDigits = max.integerDigitCount
        var min = min / pow(10, maxIntegerDigits), max = max / pow(10, maxIntegerDigits)
        var count = -maxIntegerDigits
        while count < 8 {   // maxDigits = 8
            if Int(truncating: (max - min) as NSNumber) >= 5 {  // digitDiff = 5
                return count + (count == 0 && max < 10 ? 1 : 0)
            } else {
                count += 1
                min *= 10
                max *= 10
            }
        }
        return 8
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

        let chartData = ChartData(items: items, startTimestamp: startTimestamp, endTimestamp: endTimestamp)

        // fill chart data with indicators data
        let values = points.map { $0.value }

        ChartIndicatorType.allCases.forEach { type in
            chartData.append(indicators: indicatorFactory.indicatorData(type: type, values: values))
        }

        return chartData
    }

    private func chartItem(point: ChartPoint, previousValues: [Decimal]) -> ChartItem {
        let chartItem = ChartItem(timestamp: point.timestamp)
        chartItem.added(name: .rate, value: point.value)

        let values = previousValues + [point.value]

        ChartIndicatorType.allCases.forEach { type in
            chartItem.indicators.merge(indicatorFactory.indicatorLast(type: type, values: values)) { a, _ in a }
        }

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

    func convert(item: CoinChartService.Item, interval: HsTimePeriod, currency: Currency, selectedIndicator: ChartIndicatorSet) -> CoinChartViewModel.ViewItem {
        var points = item.chartInfo.points
        var endTimestamp = item.chartInfo.endTimestamp

        var extendedPoint: ChartPoint?
        var addCurrentRate = false
        if let lastPointTimestamp = item.chartInfo.points.last?.timestamp,
           let timestamp = item.timestamp,
           let rate = item.rate,
           timestamp > lastPointTimestamp {
            // add current rate in data
            endTimestamp = max(timestamp, endTimestamp)
            points.append(ChartPoint(timestamp: timestamp, value: rate))

            // create extended point for 24h ago
            if interval == .day1, let rateDiff24 = item.rateDiff24h {
                let firstTimestamp = timestamp - 24 * 60 * 60
                let price24h = 100 * rate / (100 + rateDiff24)
                extendedPoint = ChartPoint(timestamp: firstTimestamp, value: price24h)
            }

            addCurrentRate = true
        }
        // build data with rates, volumes and indicators for points
        let data = chartData(points: points, startTimestamp: item.chartInfo.startTimestamp, endTimestamp: endTimestamp)

        // calculate item for 24h back point and add to data
        if let extendedPoint = extendedPoint {
            let values = points.filter { $0.timestamp < extendedPoint.timestamp }.map { $0.value }
            let extendedItem = chartItem(point: extendedPoint, previousValues: values)

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

        let lastIndicatorPoint = addCurrentRate && data.items.count > 2 ? data.items[data.items.count - 2] : data.items.last

        var trends = [ChartIndicatorSet: MovementTrend]()
        trends[.ema] = calculateTrend(down: lastIndicatorPoint?.indicators[.emaLong], up: lastIndicatorPoint?.indicators[.emaShort])
        trends[.macd] = calculateTrend(down: lastIndicatorPoint?.indicators[.macdSignal], up: lastIndicatorPoint?.indicators[.macd])
        trends[.rsi] = calculateRsiTrend(rsi: lastIndicatorPoint?.indicators[.rsi])

        var minRateString: String?, maxRateString: String?

        if let minRate = minRate, let maxRate = maxRate {
            let currencyScale = scale(min: minRate, max: maxRate)

            currencyFormatter.currencyCode = currency.code
            currencyFormatter.currencySymbol = currency.symbol

            currencyFormatter.minimumFractionDigits = 0
            currencyFormatter.maximumFractionDigits = max(0, currencyScale)

            minRateString = currencyFormatter.string(from: minRate as NSNumber)
            maxRateString = currencyFormatter.string(from: maxRate as NSNumber)
        }

        // make timeline for chart

        let gridInterval = ChartIntervalConverter.convert(interval: interval) // hours count
        let timeline = timelineHelper
                .timestamps(startTimestamp: data.startWindow, endTimestamp: data.endWindow, separateHourlyInterval: gridInterval)
                .map {
                    ChartTimelineItem(text: timelineHelper.text(timestamp: $0, separateHourlyInterval: gridInterval, dateFormatter: dateFormatter), timestamp: $0)
                }

        // disable indicators if chart interval less than 7d
        let correctedIndicator: ChartIndicatorSet? = [HsTimePeriod.day1].contains(interval) ? nil : selectedIndicator

        return CoinChartViewModel.ViewItem(chartData: data, chartTrend: chartTrend, chartDiff: chartDiff,
                trends: trends, minValue: minRateString, maxValue: maxRateString, timeline: timeline, selectedIndicator: correctedIndicator)
    }

    func selectedPointViewItem(chartItem: ChartItem, currency: Currency, macdSelected: Bool) -> SelectedPointViewItem? {
        guard let rate = chartItem.indicators[.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)

        currencyFormatter.currencyCode = currency.code
        currencyFormatter.currencySymbol = currency.symbol
        currencyFormatter.maximumFractionDigits = 8

        let formattedValue = currencyFormatter.string(from: rate as NSNumber)

        var rightSideMode: SelectedPointViewItem.RightSideMode
        if macdSelected {
            let macd = macdFormat(value: chartItem.indicators[.macd])
            let macdSignal = macdFormat(value: chartItem.indicators[.macdSignal])
            let macdHistogram = macdFormat(value: chartItem.indicators[.macdHistogram])
            let histogramDown = chartItem.indicators[.macdHistogram]?.isSignMinus

            rightSideMode = .macd(macdInfo: MacdInfo(macd: macd, signal: macdSignal, histogram: macdHistogram, histogramDown: histogramDown))
        } else {

            rightSideMode = .volume(value: CurrencyCompactFormatter.instance.format(currency: currency, value: chartItem.indicators[.volume].flatMap { $0.isZero ? nil : $0 }))
        }

        return SelectedPointViewItem(date: formattedDate, value: formattedValue, rightSideMode: rightSideMode)
    }

}
