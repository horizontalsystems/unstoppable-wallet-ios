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

    private func viewItem(coin: Coin, currency: Currency, marketInfo: MarketInfo?) -> RateViewItem {
        RateViewItem(
                coin: coin,
                rateExpired: marketInfo?.expired ?? false,
                rate: marketInfo.map { CurrencyValue(currency: currency, value: $0.rate) },
                diff: marketInfo?.diff
        )
    }

}

extension RateListFactory: IRateListFactory {

    func rateListViewItem(coins: [Coin], currency: Currency, marketInfos: [CoinCode: MarketInfo]) -> RateListViewItem {
        let items = coins.map { viewItem(coin: $0, currency: currency, marketInfo: marketInfos[$0.code]) }
        return RateListViewItem(currentDate: currentDateProvider.currentDate, lastUpdateTimestamp: lastUpdateTimestamp(marketInfos: marketInfos), rateViewItems: items)
    }

}
