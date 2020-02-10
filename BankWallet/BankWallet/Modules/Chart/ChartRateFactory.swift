import Foundation
import XRatesKit
import Chart
import CurrencyKit

struct ChartInfoViewItem {
    let lowValue: CurrencyValue
    let highValue: CurrencyValue

    let diff: Decimal?

    let gridIntervalType: GridIntervalType

    let points: [Chart.ChartPoint]
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
}

struct MarketInfoViewItem {
    let timestamp: TimeInterval

    let rateValue: CurrencyValue?
    let marketCapValue: CurrencyValue?

    public let volumeValue: CurrencyValue?
    public let supplyValue: CoinValue
    public let maxSupplyValue: CoinValue?
}

class ChartRateFactory: IChartRateFactory {
    enum FactoryError: Error {
        case noChartPoints
        case noPercentDelta
    }

    func chartViewItem(type: ChartType, chartInfo: ChartInfo, currency: Currency) throws -> ChartInfoViewItem {
        guard !chartInfo.points.isEmpty else {
            throw FactoryError.noChartPoints
        }
        var minimumValue = Decimal.greatestFiniteMagnitude
        var maximumValue = Decimal.zero
        chartInfo.points.forEach { point in
            minimumValue = min(minimumValue, point.value)
            maximumValue = max(maximumValue, point.value)
        }
        var diff: Decimal?
        if let first = chartInfo.points.first(where: { point in !point.value.isZero }), let last = chartInfo.points.last {
            diff = (last.value - first.value) / first.value * 100
        }
        let lowValue = CurrencyValue(currency: currency, value: minimumValue)
        let highValue = CurrencyValue(currency: currency, value: maximumValue)

        let points = chartInfo.points.map { ChartPoint(timestamp: $0.timestamp, value: $0.value, volume: $0.volume) }
        return ChartInfoViewItem(lowValue: lowValue, highValue: highValue, diff: diff,
                gridIntervalType: GridIntervalConverter.convert(chartType: type), points: points,
                startTimestamp: chartInfo.startTimestamp, endTimestamp: chartInfo.endTimestamp)
    }

    func marketInfoViewItem(marketInfo: MarketInfo, coin: Coin, currency: Currency) -> MarketInfoViewItem {
        let rateValue = CurrencyValue(currency: currency, value: marketInfo.rate)
        let marketCapValue = CurrencyValue(currency: currency, value: marketInfo.marketCap)
        let volume = CurrencyValue(currency: currency, value: marketInfo.volume)
        let supply = CoinValue(coin: coin, value: marketInfo.supply)

        let maxSupply = MaxSupplyMap.maxSupplies[coin.code].map { CoinValue(coin: coin, value: $0) }

        return MarketInfoViewItem(timestamp: marketInfo.timestamp, rateValue: rateValue, marketCapValue: marketCapValue, volumeValue: volume, supplyValue: supply, maxSupplyValue: maxSupply)
    }

}
