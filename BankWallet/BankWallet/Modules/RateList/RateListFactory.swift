import Foundation
import XRatesKit
import CurrencyKit

class RateListFactory {
    private let currentDateProvider: ICurrentDateProvider

    init(currentDateProvider: ICurrentDateProvider) {
        self.currentDateProvider = currentDateProvider
    }

    private func lastUpdateTimestamp(marketInfos: [CoinCode: MarketInfo]) -> TimeInterval? {
        let allTimestamps = marketInfos.map { $0.value.timestamp }
        return allTimestamps.max()
    }

    private func viewItem(coin: Coin, currency: Currency, marketInfo: MarketInfo) -> RateViewItem {
        RateViewItem(
                coinCode: coin.code,
                coinTitle: coin.title,
                blockchainType: coin.type.blockchainType,
                rateExpired: marketInfo.expired,
                rate: CurrencyValue(currency: currency, value: marketInfo.rate),
                diff: marketInfo.diff
        )
    }

    private func topRateViewItem(currency: Currency, topMarket: TopMarket) -> RateViewItem {
        RateViewItem(
                coinCode: topMarket.coinCode,
                coinTitle: topMarket.coinName,
                blockchainType: nil,
                rateExpired: topMarket.marketInfo.expired,
                rate: CurrencyValue(currency: currency, value: topMarket.marketInfo.rate),
                diff: topMarket.marketInfo.diff
        )
    }

}

extension RateListFactory: IRateListFactory {

    func rateListViewItem(coins: [Coin], currency: Currency, marketInfos: [CoinCode: MarketInfo], topMarkets: [TopMarket]) -> RateListViewItem {
        let marketInfoItems = coins.compactMap { coin in marketInfos[coin.code].map { viewItem(coin: coin, currency: currency, marketInfo: $0) } }
        let topRateViewItems = topMarkets.map { topRateViewItem(currency: currency, topMarket: $0) }

        return RateListViewItem(
                currentDate: currentDateProvider.currentDate, lastUpdateTimestamp: lastUpdateTimestamp(marketInfos: marketInfos),
                rateViewItems: marketInfoItems, topRateViewItems: topRateViewItems
        )
    }

}
