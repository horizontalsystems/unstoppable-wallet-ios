import Foundation
import XRatesKit

protocol IRateTopListView: AnyObject {
    func set(viewItems: [RateTopListModule.ViewItem])
    func set(lastUpdated: Date)
    func refresh()
    func setSpinner(visible: Bool)
    func setSortButton(enabled: Bool)
}

protocol IRateTopListViewDelegate {
    func onLoad()
    func onSelect(index: Int)
    func onTapSort()
}

protocol IRateTopListInteractor {
    var wallets: [Wallet] { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfos(currencyCode: String)
    func updateTopMarkets(currencyCode: String)
}

protocol IRateTopListInteractorDelegate: AnyObject {
    func didReceive(marketInfos: [String: MarketInfo])
    func didReceive(topMarkets: [RateTopListModule.TopMarketItem])
}

protocol IRateTopListRouter {
    func showChart(coinCode: String, coinTitle: String, coinType: CoinType?)
    func showSortType(selected: RateTopListModule.SortType, onSelect: @escaping (RateTopListModule.SortType) -> ())
}

class RateTopListModule {

    struct TopMarketItem {
        let rank: Int

        let coinCode: String
        let coinName: String
        let coinType: CoinType?

        var marketInfo: MarketInfo
    }

    struct ViewItem {
        let rank: Int
        let coinCode: String
        let coinTitle: String
        let rate: RateViewItem
    }

    enum SortType: CaseIterable {
        case rank
        case topWinners
        case topLosers

        var title: String {
            switch self {
            case .rank: return "top100_list.sort_type.rank".localized
            case .topWinners: return "top100_list.sort_type.top_winners".localized
            case .topLosers: return "top100_list.sort_type.top_losers".localized
            }
        }
    }

}
