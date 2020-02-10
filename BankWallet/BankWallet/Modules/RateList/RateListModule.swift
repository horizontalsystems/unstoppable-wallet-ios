import Foundation
import XRatesKit
import CurrencyKit

protocol IRateListView: class {
    func show(item: RateListViewItem)
}

protocol IRateListViewDelegate {
    func viewDidLoad()
}

protocol IRateListInteractor {
    var currency: Currency { get }
    var wallets: [Wallet] { get }
    var featuredCoins: [Coin] { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfos(currencyCode: String)
}

protocol IRateListInteractorDelegate: class {
    func didReceive(marketInfos: [String: MarketInfo])
}

protocol IRateListRouter {
}

protocol IRateListFactory {
    func rateListViewItem(coins: [Coin], currency: Currency, marketInfos: [CoinCode: MarketInfo]) -> RateListViewItem
}

protocol IRateListSorter {
    func smartSort(for coins: [Coin], featuredCoins: [Coin]) -> [Coin]
}

struct RateListViewItem {
    let currentDate: Date
    let lastUpdateTimestamp: TimeInterval?
    let rateViewItems: [RateViewItem]
}

struct RateViewItem {
    let coin: Coin
    var rateExpired: Bool
    var rate: CurrencyValue?
    var diff: Decimal?

    var hash: String {
        var fields = [String]()
        fields.append(coin.code)
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
