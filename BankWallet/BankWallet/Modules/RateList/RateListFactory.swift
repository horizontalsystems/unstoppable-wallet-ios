import Foundation
import XRatesKit

class RateListFactory {
    private let currentDateProvider: ICurrentDateProvider

    init(currentDateProvider: ICurrentDateProvider) {
        self.currentDateProvider = currentDateProvider
    }

    private func lastUpdateTimestamp(marketInfos: [CoinCode: MarketInfo]) -> TimeInterval {
        let allTimestamps = marketInfos.map { $0.1.timestamp }
        return allTimestamps.max() ?? 0
    }

    private func viewItem(coin: Coin, currency: Currency, marketInfo: MarketInfo?) -> RateViewItem {
        var rateValue: CurrencyValue?
        if let rate = marketInfo?.rate {
            rateValue = CurrencyValue(currency: currency, value: rate)
        }
        return RateViewItem(coin: coin, rateExpired: marketInfo?.expired ?? false, rate: rateValue, diff: marketInfo?.diff)
    }

}

extension RateListFactory: IRateListFactory {

    func marketInfoViewItem(coins: [Coin], currency: Currency, marketInfos: [CoinCode: MarketInfo]) -> RateListViewItem {
        let items = coins.map { viewItem(coin: $0, currency: currency, marketInfo: marketInfos[$0.code]) }
        return RateListViewItem(currentDate: currentDateProvider.currentDate, lastUpdateTimestamp: lastUpdateTimestamp(marketInfos: marketInfos), rateViewItems: items)
    }

}
