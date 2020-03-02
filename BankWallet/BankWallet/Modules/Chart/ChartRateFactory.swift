import Foundation
import XRatesKit
import Chart
import CurrencyKit

class ChartRateFactory: IChartRateFactory {
    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 8
        return formatter
    }()

    private func roundedFormat(coin: Coin, value: Decimal?) -> String? {
        guard let value = value, let formattedValue = coinFormatter.string(from: value as NSNumber) else {
            return nil
        }

        return "\(formattedValue) \(coin.code)"
    }

    private func postViewItemDate(timestamp: TimeInterval) -> String {
        var interval = Int(Date().timeIntervalSince1970 - timestamp) / 60       // interval from post in minutes
        if interval < 60 {
            return "timestamp.min_ago".localized(max(1, interval))
        }
        interval /= 60                                                          // interval in hours
        if interval < 24 {
            return "timestamp.hours_ago".localized(interval)
        }
        interval /= 24                                                           // interval in days
        return "timestamp.days_ago".localized(interval)
    }

    private func viewItem(marketInfo: MarketInfo, currency: Currency, coin: Coin) -> MarketInfoViewItem {
        let marketCap = CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.marketCap)
        let volume = CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.volume)

        let supply = roundedFormat(coin: coin, value: marketInfo.supply)
        let maxSupply = roundedFormat(coin: coin, value: MaxSupplyMap.maxSupplies[coin.code]) ?? "n/a".localized

        return MarketInfoViewItem(marketCap: marketCap, volume: volume, supply: supply, maxSupply: maxSupply)
    }

    func chartViewItem(type: ChartType, allTypes: [ChartType], chartInfoStatus: ChartDataStatus<ChartInfo>,
                       marketInfoStatus: ChartDataStatus<MarketInfo>, postsStatus: ChartDataStatus<[CryptoNewsPost]>, coin: Coin, currency: Currency) -> ChartViewItem {

        let index = allTypes.firstIndex(of: type) ?? 0

        let chartStatus: ChartDataStatus<ChartInfoViewItem> = chartInfoStatus.convert {
            let points = $0.points.map { ChartPoint(timestamp: $0.timestamp, value: $0.value, volume: $0.volume) }
            return ChartInfoViewItem(gridIntervalType: GridIntervalConverter.convert(chartType: type), points: points, startTimestamp: $0.startTimestamp, endTimestamp: $0.endTimestamp)
        }
        let postsStatus: ChartDataStatus<[PostViewItem]> = postsStatus.convert {
            $0.map { PostViewItem(title: $0.title, subtitle: postViewItemDate(timestamp: $0.timestamp)) }
        }
        let marketStatus: ChartDataStatus<MarketInfoViewItem> = marketInfoStatus.convert {
            viewItem(marketInfo: $0, currency: currency, coin: coin)
        }

        var diff: Decimal?
        if let points = chartInfoStatus.data?.points {
            if let first = points.first(where: { point in !point.value.isZero }), let last = points.last {
                diff = (last.value - first.value) / first.value * 100
            }
        }
        var currentRate: String?
        if let rate = marketInfoStatus.data?.rate {
            let rateValue = CurrencyValue(currency: currency, value: rate)
            currentRate = ValueFormatter.instance.format(currencyValue: rateValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        }

        return ChartViewItem(selectedIndex: index, diff: diff, currentRate: currentRate, chartInfoStatus: chartStatus, marketInfoStatus: marketStatus, postsStatus: postsStatus)
    }

    func selectedPointViewItem(type: ChartType, chartPoint: Chart.ChartPoint, coin: Coin, currency: Currency) -> SelectedPointViewItem {
        let date = Date(timeIntervalSince1970: chartPoint.timestamp)
        let formattedTime = [ChartType.day, ChartType.week].contains(type) ? DateHelper.instance.formatTimeOnly(from: date) : nil
        let formattedDate = DateHelper.instance.formateShortDateOnly(date: date)

        currencyFormatter.currencyCode = currency.code
        currencyFormatter.currencySymbol = currency.symbol
        let formattedValue = currencyFormatter.string(from: chartPoint.value as NSNumber)

        return SelectedPointViewItem(date: formattedDate, time: formattedTime, value: formattedValue, volume: CurrencyCompactFormatter.instance.format(currency: currency, value: chartPoint.volume))
    }

}
