import Foundation
import XRatesKit
import CurrencyKit

protocol IRateListView: class {
    func show(item: RateListViewItem)
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
    func subscribeToMarketInfos(currencyCode: String)
    func updateTopMarkets(currencyCode: String)
}

protocol IRateListInteractorDelegate: class {
    func didReceive(marketInfos: [String: MarketInfo])
    func didReceive(topMarkets: [TopMarket])
}

protocol IRateListRouter {
    func showChart(coinCode: String, coinTitle: String)
}

protocol IRateListFactory {
    func rateListViewItem(coins: [Coin], currency: Currency, marketInfos: [CoinCode: MarketInfo], topMarkets: [TopMarket]) -> RateListViewItem
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
    let rateViewItems: [RateViewItem]
    let topRateViewItems: [RateViewItem]
}

struct RateViewItem {
    let coinCode: String
    let coinTitle: String
    let blockchainType: String?
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

}
