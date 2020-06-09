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
    private var topMarkets = [TopMarket]()

    init(currency: Currency, interactor: IRateTopListInteractor, router: IRateTopListRouter) {
        self.currency = currency
        self.interactor = interactor
        self.router = router
    }

    private func syncMarketInfo() {
        for (coinCode, marketInfo) in marketInfos {
            for (topMarketIndex, topMarket) in topMarkets.enumerated() {
                if coinCode == topMarket.coinCode {
                    topMarkets[topMarketIndex].marketInfo = marketInfo
                }
            }
        }
    }

    private func syncView() {
        let viewItems = topMarkets.map { topMarket in
            viewItem(topMarket: topMarket)
        }
        view?.set(viewItems: viewItems)

        let timestamps = topMarkets.map { $0.marketInfo.timestamp }
        if let timestamp = timestamps.max() {
            view?.set(lastUpdated: Date(timeIntervalSince1970: timestamp))
        }
    }

    private func viewItem(topMarket: TopMarket) -> RateTopListModule.ViewItem {
        RateTopListModule.ViewItem(
                coinCode: topMarket.coinCode,
                coinTitle: topMarket.coinName,
                rate: RateViewItem(
                        currencyValue: CurrencyValue(currency: currency, value: topMarket.marketInfo.rate),
                        diff: topMarket.marketInfo.diff,
                        dimmed: topMarket.marketInfo.expired
                )
        )
    }

}

extension RateTopListPresenter: IRateTopListViewDelegate {

    func onLoad() {
        coins = interactor.wallets.map { $0.coin }

        coins.forEach { coin in
            marketInfos[coin.code] = interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code)
        }

        syncView()

        interactor.subscribeToMarketInfos(currencyCode: currency.code)
        interactor.updateTopMarkets(currencyCode: currency.code)
    }

    func onSelect(index: Int) {
        let topMarket = topMarkets[index]
        router.showChart(coinCode: topMarket.coinCode, coinTitle: topMarket.coinName)
    }

}

extension RateTopListPresenter: IRateTopListInteractorDelegate {

    func didReceive(marketInfos: [String: MarketInfo]) {
        self.marketInfos = marketInfos

        syncMarketInfo()
        syncView()
        view?.refresh()

        interactor.updateTopMarkets(currencyCode: currency.code)
    }

    func didReceive(topMarkets: [TopMarket]) {
        self.topMarkets = topMarkets

        syncMarketInfo()
        syncView()
        view?.refresh()
    }

}
