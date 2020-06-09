import Foundation
import XRatesKit

protocol IRateTopListView: AnyObject {
    func set(viewItems: [RateTopListModule.ViewItem])
    func set(lastUpdated: Date)
    func refresh()
}

protocol IRateTopListViewDelegate {
    func onLoad()
    func onSelect(index: Int)
}

protocol IRateTopListInteractor {
    var wallets: [Wallet] { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfos(currencyCode: String)
    func updateTopMarkets(currencyCode: String)
}

protocol IRateTopListInteractorDelegate: AnyObject {
    func didReceive(marketInfos: [String: MarketInfo])
    func didReceive(topMarkets: [TopMarket])
}

protocol IRateTopListRouter {
    func showChart(coinCode: String, coinTitle: String)
}

class RateTopListModule {

    struct ViewItem {
        let coinCode: String
        let coinTitle: String
        let rate: RateViewItem
    }

}
