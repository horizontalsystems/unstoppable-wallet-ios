import Foundation
import XRatesKit
import CurrencyKit

class RateListPresenter {
    weak var view: IRateListView?

    private let interactor: IRateListInteractor
    private let router: IRateListRouter
    private let rateListSorter: IRateListSorter
    private let factory: IRateListFactory

    private var coins = [Coin]()
    private let currency: Currency
    private var marketInfos = [String: MarketInfo]()
    private var topMarkets = [MarketInfo]()

    init(interactor: IRateListInteractor, router: IRateListRouter, rateListSorter: IRateListSorter, factory: IRateListFactory) {
        self.interactor = interactor
        self.router = router
        self.rateListSorter = rateListSorter
        self.factory = factory

        currency = interactor.currency
    }

    private func syncListsAndShow() {
        for (coin, marketInfo) in marketInfos {
            for (topMarketIndex, topMarket) in topMarkets.enumerated() {
                if marketInfo.coinCode == topMarket.coinCode {
                    if marketInfo.timestamp > topMarket.timestamp {
                        topMarkets[topMarketIndex] = marketInfo
                    } else if marketInfo.timestamp < topMarket.timestamp {
                        marketInfos[coin] = topMarket
                    }
                }
            }
        }

        let item = factory.rateListViewItem(coins: coins, currency: currency, marketInfos: marketInfos, topMarkets: topMarkets)
        view?.show(item: item)
    }

}

extension RateListPresenter: IRateListViewDelegate {

    func viewDidLoad() {
        coins = rateListSorter.smartSort(for: interactor.wallets.map { $0.coin }, featuredCoins: interactor.featuredCoins)

        marketInfos.removeAll()
        coins.forEach { coin in
            marketInfos[coin.code] = interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code)
        }
        topMarkets = interactor.topMarketInfos(currencyCode: currency.code)

        let item = factory.rateListViewItem(coins: coins, currency: currency, marketInfos: marketInfos, topMarkets: topMarkets)
        view?.show(item: item)

        interactor.subscribeToMarketInfos(currencyCode: currency.code)
        interactor.subscribeToTopMarketInfos()
    }

    func onSelect(viewItem: RateViewItem) {
        guard viewItem.diff != nil else {
            return
        }

        router.showChart(coinCode: viewItem.coinCode, coinTitle: viewItem.coinTitle)
    }

}

extension RateListPresenter: IRateListInteractorDelegate {

    func didReceive(marketInfos: [String: MarketInfo]) {
        self.marketInfos = marketInfos
        syncListsAndShow()
    }

    func didReceive(topMarketInfos: [MarketInfo]) {
        self.topMarkets = topMarketInfos
        syncListsAndShow()
    }

}
