import Foundation
import XRatesKit
import CurrencyKit

protocol IRateListView: class {
    func show(item: RateListViewItem)
    func show(topRateViewItems: [RateViewItem])
}

protocol IRateListViewDelegate {
    func viewDidLoad()
    func onSelect(viewItem: RateViewItem)
}

protocol IRateListInteractor {
    var currency: Currency { get }
    var wallets: [Wallet] { get }
    var featuredCoins: [Coin] { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func topMarketInfos(currencyCode: String) -> [MarketInfo]
    func subscribeToMarketInfos(currencyCode: String)
    func subscribeToMarketInfos()
}

protocol IRateListInteractorDelegate: class {
    func didReceive(marketInfos: [String: MarketInfo])
    func didReceive(topMarketInfos: [MarketInfo])
}

protocol IRateListRouter {
    func showChart(coinCode: String, coinTitle: String)
}

protocol IRateListFactory {
    func rateListViewItem(coins: [Coin], currency: Currency, marketInfos: [CoinCode: MarketInfo]) -> RateListViewItem
    func topRateViewItem(currency: Currency, topMarketInfo: MarketInfo) -> RateViewItem
}

protocol IRateListSorter {
    func smartSort(for coins: [Coin], featuredCoins: [Coin]) -> [Coin]
}

protocol IRateListDelegate: AnyObject {
    func showChart(coinCode: String, coinTitle: String)
}

struct RateListViewItem {
    let currentDate: Date
    let lastUpdateTimestamp: TimeInterval?
    var rateViewItems: [RateViewItem]
}

struct RateViewItem {
    let coinCode: String
    let coinTitle: String
    let blockchainType: String?
    var timestamp: TimeInterval
    var rateExpired: Bool
    var rate: CurrencyValue?
    var diff: Decimal?

    var hash: String {
        var fields = [String]()
        fields.append(coinCode)
        if let rate = rate {
            fields.append(rate.value.description)
        }
        fields.append("\(rateExpired)")
        if let diff = diff {
            fields.append(diff.description)
        }
        return fields.joined(separator: "_")
    }

    func sameCoinAs(_ other: RateViewItem) -> Bool {
        self.coinCode == other.coinCode && self.coinTitle == other.coinTitle
    }

    mutating func updateRate(with other: RateViewItem) {
        rateExpired = other.rateExpired
        rate = other.rate
        diff = other.diff
    }

}
