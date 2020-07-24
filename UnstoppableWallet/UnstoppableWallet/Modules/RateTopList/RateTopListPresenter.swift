import Foundation
import XRatesKit
import CurrencyKit

class RateTopListPresenter {
    weak var view: IRateTopListView?

    private let currency: Currency
    private let interactor: IRateTopListInteractor
    private let router: IRateTopListRouter

    private var coins = [Coin]()
    private var marketInfos = [String: MarketInfo]()
    private var items = [RateTopListModule.TopMarketItem]()

    private var sortType: RateTopListModule.SortType = .rank

    init(currency: Currency, interactor: IRateTopListInteractor, router: IRateTopListRouter) {
        self.currency = currency
        self.interactor = interactor
        self.router = router
    }

    private func syncSort() {
        switch sortType {
        case .rank:
            items.sort { $0.rank < $1.rank }
        case .topWinners:
            items.sort { $0.topMarket.marketInfo.diff > $1.topMarket.marketInfo.diff }
        case .topLosers: ()
            items.sort { $0.topMarket.marketInfo.diff < $1.topMarket.marketInfo.diff }
        }
    }

    private func syncMarketInfo() {
        for (coinCode, marketInfo) in marketInfos {
            for (itemIndex, item) in items.enumerated() {
                if coinCode == item.topMarket.coinCode {
                    items[itemIndex].topMarket.marketInfo = marketInfo
                }
            }
        }
    }

    private func syncView() {
        let viewItems = items.map { item in
            viewItem(item: item)
        }
        view?.set(viewItems: viewItems)

        let timestamps = items.map { $0.topMarket.marketInfo.timestamp }
        if let timestamp = timestamps.max() {
            view?.set(lastUpdated: Date(timeIntervalSince1970: timestamp))
        }
    }

    private func viewItem(item: RateTopListModule.TopMarketItem) -> RateTopListModule.ViewItem {
        RateTopListModule.ViewItem(
                rank: item.rank,
                coinCode: item.topMarket.coinCode,
                coinTitle: item.topMarket.coinName,
                rate: RateViewItem(
                        currencyValue: CurrencyValue(currency: currency, value: item.topMarket.marketInfo.rate),
                        diff: item.topMarket.marketInfo.diff,
                        dimmed: item.topMarket.marketInfo.expired
                )
        )
    }

    private func onUpdate(sortType: RateTopListModule.SortType) {
        self.sortType = sortType

        syncSort()
        syncView()
        view?.refresh()
    }

}

extension RateTopListPresenter: IRateTopListViewDelegate {

    func onLoad() {
        coins = interactor.wallets.map { $0.coin }

        coins.forEach { coin in
            marketInfos[coin.code] = interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code)
        }

        syncView()
        view?.setSpinner(visible: true)
        view?.setSortButton(enabled: false)

        interactor.subscribeToMarketInfos(currencyCode: currency.code)
        interactor.updateTopMarkets(currencyCode: currency.code)
    }

    func onSelect(index: Int) {
        let item = items[index]

        router.showChart(coinCode: item.topMarket.coinCode, coinTitle: item.topMarket.coinName)
    }

    func onTapSort() {
        router.showSortType(selected: sortType) { [weak self] sortType in
            self?.onUpdate(sortType: sortType)
        }
    }

}

extension RateTopListPresenter: IRateTopListInteractorDelegate {

    func didReceive(marketInfos: [String: MarketInfo]) {
        self.marketInfos = marketInfos

        syncMarketInfo()
        syncSort()
        syncView()
        view?.refresh()

        interactor.updateTopMarkets(currencyCode: currency.code)
    }

    func didReceive(topMarkets: [TopMarket]) {
        items = topMarkets.enumerated().map { index, topMarket in
            RateTopListModule.TopMarketItem(rank: index + 1, topMarket: topMarket)
        }

        view?.setSpinner(visible: false)
        view?.setSortButton(enabled: true)

        syncMarketInfo()
        syncSort()
        syncView()
        view?.refresh()
    }

}
