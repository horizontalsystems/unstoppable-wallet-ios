import Foundation
import XRatesKit
import CurrencyKit
import LanguageKit
import Chart

class ChartRateFactory: IChartRateFactory {
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

            item.add(name: .rate, value: point.value)
            item.add(name: .volume, value: point.volume ?? 0)

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
        chartItem.add(name: .rate, value: point.value)
        chartItem.add(name: .volume, value: 0)

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

    private func convert(chartInfo: ChartInfo, marketInfo: MarketInfo?, chartType: ChartType, currency: Currency) -> ChartDataViewItem {
        var points = chartInfo.points
        var endTimestamp = chartInfo.endTimestamp

        var addCurrentRate = false
        if let marketInfo = marketInfo, let lastPointTimestamp = chartInfo.points.last?.timestamp, marketInfo.timestamp > lastPointTimestamp {
            // add current rate in data
            endTimestamp = max(marketInfo.timestamp, endTimestamp)
            points.append(ChartPoint(timestamp: marketInfo.timestamp, value: marketInfo.rate, volume: nil))
            addCurrentRate = true
        }
        // build data with rates, volumes and indicators for points
        let data = chartData(points: points, startTimestamp: chartInfo.startTimestamp, endTimestamp: endTimestamp)

        // remove non-visible items
        data.items = data.items.filter { item in item.timestamp >= data.startWindow }

        // calculate min and max limit texts
        let rates = data.values(name: .rate)
        let minRate = rates.min()
        let maxRate = rates.max()

        // determine chart growing state. when chart not full - it's nil
        var chartTrend: MovementTrend = .neutral
        var chartDiff: Decimal?
        if let first = data.items.first(where: { ($0.indicators[.rate] ?? 0) != 0 }), let last = data.items.last, !chartInfo.expired, let firstRate = first.indicators[.rate], let lastRate = last.indicators[.rate] {
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

        let gridInterval = ChartTypeIntervalConverter.convert(chartType: chartType) // hours count
        let timeline = timelineHelper
                .timestamps(startTimestamp: data.startWindow, endTimestamp: data.endWindow, separateHourlyInterval: gridInterval)
                .map {
                    ChartTimelineItem(text: timelineHelper.text(timestamp: $0, separateHourlyInterval: gridInterval, dateFormatter: dateFormatter), timestamp: $0)
                }

        return ChartDataViewItem(chartData: data, chartTrend: chartTrend, chartDiff: chartDiff,
                trends: trends, minValue: minRateString, maxValue: maxRateString, timeline: timeline)
    }

    func chartViewItem(chartDataStatus: DataStatus<ChartInfo>, marketInfoStatus: DataStatus<MarketInfo>, chartType: ChartType, coinCode: String, currency: Currency, selectedIndicator: ChartIndicatorSet, coin: Coin?, priceAlert: PriceAlert?, alertsOn: Bool) -> ChartViewItem {
        let chartDataStatusViewItem: DataStatus<ChartDataViewItem> = chartDataStatus.map {
            convert(chartInfo: $0, marketInfo: marketInfoStatus.data, chartType: chartType, currency: currency)
        }

        let marketStatus: DataStatus<MarketInfoViewItem> = marketInfoStatus.map {
            viewItem(marketInfo: $0, currency: currency, coinCode: coinCode)
        }

        var currentRate: String?
        if let rate = marketInfoStatus.data?.rate {
            let rateValue = CurrencyValue(currency: currency, value: rate)
            currentRate = ValueFormatter.instance.format(currencyValue: rateValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        }

        let priceAlertMode: ChartPriceAlertMode
        if !alertsOn || coin == nil {
            priceAlertMode = .hidden
        } else {
            priceAlertMode = priceAlert?.changeState != .off || priceAlert?.trendState != .off ? .on : .off
        }

        return ChartViewItem(currentRate: currentRate, chartDataStatus: chartDataStatusViewItem, marketInfoStatus: marketStatus, selectedIndicator: selectedIndicator, priceAlertMode: priceAlertMode)
    }

    func selectedPointViewItem(chartItem: ChartItem, type: ChartType, currency: Currency, macdSelected: Bool) -> SelectedPointViewItem? {
        guard let rate = chartItem.indicators[.rate] else {
            return nil
        }

        let chartPoint = ChartPoint(timestamp: chartItem.timestamp, value: rate, volume: chartItem.indicators[.volume])

        let date = Date(timeIntervalSince1970: chartPoint.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)

        currencyFormatter.currencyCode = currency.code
        currencyFormatter.currencySymbol = currency.symbol
        currencyFormatter.maximumFractionDigits = 8

        let formattedValue = currencyFormatter.string(from: chartPoint.value as NSNumber)

        var rightSideMode: SelectedPointViewItem.RightSideMode
        if macdSelected{
            let macd = macdFormat(value: chartItem.indicators[.macd])
            let macdSignal = macdFormat(value: chartItem.indicators[.macdSignal])
            let macdHistogram = macdFormat(value: chartItem.indicators[.macdHistogram])
            let histogramDown = chartItem.indicators[.macdHistogram]?.isSignMinus

            rightSideMode = .macd(macdInfo: MacdInfo(macd: macd, signal: macdSignal, histogram: macdHistogram, histogramDown: histogramDown))
        } else {
            rightSideMode = .volume(value: CurrencyCompactFormatter.instance.format(currency: currency, value: chartPoint.volume))
        }

        return SelectedPointViewItem(date: formattedDate, value: formattedValue, rightSideMode: rightSideMode)
    }

    private func viewItem(marketInfo: MarketInfo, currency: Currency, coinCode: String) -> MarketInfoViewItem {
        let marketCapText = marketInfo.marketCap.isZero ? "n/a".localized : CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.marketCap)
        let marketCap = MarketInfoViewItem.Value(value: marketCapText, accent: !marketInfo.marketCap.isZero)

        let volumeText = marketInfo.volume.isZero ? "n/a".localized : CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.volume)
        let volume = MarketInfoViewItem.Value(value: volumeText, accent: !marketInfo.volume.isZero)

        let supply = roundedFormat(coinCode: coinCode, value: marketInfo.supply)

        let coinData = CoinInfoMap.data[coinCode]

        let maxSupplyText = roundedFormat(coinCode: coinCode, value: coinData?.supply)
        let maxSupply = MarketInfoViewItem.Value(value: maxSupplyText, accent: coinData?.supply != nil)

        let parsedDate = coinData?
                .startDate
                .map { DateHelper.instance.parseDateOnly(string: $0) }?
                .map { DateHelper.instance.formatFullDateOnly(from: $0) }

        let startDate = MarketInfoViewItem.Value(value: parsedDate ?? "n/a".localized, accent: coinData?.startDate != nil)

        let website = MarketInfoViewItem.Value(value: coinData?.website ?? "n/a".localized, accent: coinData?.website != nil)

        return MarketInfoViewItem(marketCap: marketCap, volume: volume, supply: supply, maxSupply: maxSupply, startDate: startDate, website: website)
    }

}
