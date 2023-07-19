import Foundation
import UIKit
import Chart
import CurrencyKit
import LanguageKit
import MarketKit

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
                    if index > 0 {
                        points.remove(at: index - 1)
                    }
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

        let values = points.map {
            $0.value
        }

        return ChartModule.ViewItem(
                value: ValueFormatter.instance.formatFull(currencyValue: CurrencyValue(currency: currency, value: item.rate)),
                valueDescription: nil,
                rightSideMode: .none,
                chartData: ChartData(items: items, startWindow: firstPoint.timestamp, endWindow: lastPoint.timestamp),
                indicators: item.indicators,
                chartTrend: lastPoint.value > firstPoint.value ? .up : .down,
                chartDiff: (lastPoint.value - firstPoint.value) / firstPoint.value * 100,
                minValue: values.min().flatMap {
                    ValueFormatter.instance.formatFull(currency: currency, value: $0)
                },
                maxValue: values.max().flatMap {
                    ValueFormatter.instance.formatFull(currency: currency, value: $0)
                }
        )
    }

    func selectedPointViewItem(chartItem: ChartItem, indicators: [ChartIndicator], firstChartItem: ChartItem?, currency: Currency) -> ChartModule.SelectedPointViewItem? {
        guard let rate = chartItem.indicators[ChartData.rate] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: chartItem.timestamp)
        let formattedDate = DateHelper.instance.formatFullTime(from: date)
        let formattedValue = ValueFormatter.instance.formatFull(currency: currency, value: rate)

        let volumeString: String? = chartItem.indicators[ChartData.volume].flatMap {
            if $0.isZero {
                return nil
            }
            return ValueFormatter.instance.formatShort(currency: currency, value: $0).map {
                "chart.selected.volume".localized + " " + $0
            }
        }

        let visibleMaIndicators = indicators
                .filter {
                    $0.onChart && $0.enabled
                }
                .compactMap {
                    $0 as? MaIndicator
                }

        let visibleBottomIndicators = indicators
                .filter {
                    !$0.onChart && $0.enabled
                }

        let rightSideMode: ChartModule.RightSideMode
        // If no any visible indicators, we show only volume
        if visibleMaIndicators.isEmpty && visibleBottomIndicators.isEmpty {
            rightSideMode = .volume(value: volumeString)
        } else {
            let maPairs = visibleMaIndicators.compactMap { ma -> (Decimal, UIColor)? in
                // get value if ma-indicator and it's color
                guard let value = chartItem.indicators[ma.json] else {
                    return nil
                }
                let color = ma.configuration.color.value.withAlphaComponent(1)
                return (value, color)
            }
            // build top-line string
            let topLineString = NSMutableAttributedString()
            let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.right

            for (index, pair) in maPairs.enumerated() {
                let formatted = ValueFormatter.instance.formatFull(value: pair.0, decimalCount: 8, showSign: pair.0 < 0)
                topLineString.append(NSAttributedString(string: formatted ?? "", attributes: [.foregroundColor: pair.1.withAlphaComponent(1), .paragraphStyle: paragraphStyle]))
                if index < maPairs.count - 1 {
                    topLineString.append(NSAttributedString(string: " "))
                }
            }
            // build bottom-line string
            let bottomLineString = NSMutableAttributedString()
            switch visibleBottomIndicators.first {
            case let rsi as RsiIndicator:
                let value = chartItem.indicators[rsi.json]
                let formatted = value.flatMap {
                    ValueFormatter.instance.formatFull(value: $0, decimalCount: 2, showSign: $0 < 0)
                }
                bottomLineString.append(NSAttributedString(string: formatted ?? "", attributes: [.foregroundColor: rsi.configuration.color.value.withAlphaComponent(1), .paragraphStyle: paragraphStyle]))
            case let macd as MacdIndicator:
                var pairs = [(Decimal, UIColor)]()
                // histogram pair
                let histogramName = MacdIndicator.MacdType.histogram.name(id: macd.json)
                if let histogramValue = chartItem.indicators[histogramName] {
                    let color = histogramValue >= 0 ? macd.configuration.positiveColor : macd.configuration.negativeColor
                    pairs.append((histogramValue, color.value))
                }
                let signalName = MacdIndicator.MacdType.signal.name(id: macd.json)
                if let signalValue = chartItem.indicators[signalName] {
                    pairs.append((signalValue, macd.configuration.fastColor.value))
                }
                let macdName = MacdIndicator.MacdType.macd.name(id: macd.json)
                if let macdValue = chartItem.indicators[macdName] {
                    pairs.append((macdValue, macd.configuration.longColor.value))
                }
                for (index, pair) in pairs.enumerated() {
                    let formatted = ValueFormatter.instance.formatFull(value: pair.0, decimalCount: 8, showSign: pair.0 < 0)
                    bottomLineString.append(NSAttributedString(string: formatted ?? "", attributes: [.foregroundColor: pair.1.withAlphaComponent(1), .paragraphStyle: paragraphStyle]))
                    if index < pairs.count - 1 {
                        bottomLineString.append(NSAttributedString(string: " "))
                    }
                }
            default:
                if let volume = volumeString {
                    bottomLineString.append(NSAttributedString(string: volume, attributes: [.foregroundColor: UIColor.themeGray, .paragraphStyle: paragraphStyle]))
                }
            }

            rightSideMode = .indicators(top: topLineString, bottom: bottomLineString)
        }

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
        case .byStartTime: return false
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