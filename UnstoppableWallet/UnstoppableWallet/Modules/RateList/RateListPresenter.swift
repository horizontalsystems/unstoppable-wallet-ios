import Foundation
import XRatesKit
import CurrencyKit

class RateListPresenter {
    weak var view: IRateListView?

    private let currency: Currency
    private let interactor: IRateListInteractor
    private let router: IRateListRouter

    private var coins = [Coin]()
    private var marketInfos = [String: MarketInfo]()

    init(currency: Currency, interactor: IRateListInteractor, router: IRateListRouter) {
        self.currency = currency
        self.interactor = interactor
        self.router = router
    }

    private func orderedCoins(activeCoins: [Coin], featuredCoins: [Coin]) -> [Coin] {
        let activeFeaturedCoins = featuredCoins.filter { activeCoins.contains($0) }
        let activeNonFeaturedCoins = activeCoins.filter { !featuredCoins.contains($0) }

        return activeFeaturedCoins + activeNonFeaturedCoins.sorted { $0.code < $1.code }
    }

    private func smartList(activeCoins: [Coin], featuredCoins: [Coin]) -> [Coin] {
        guard !activeCoins.isEmpty else {
            return featuredCoins
        }

        return orderedCoins(activeCoins: activeCoins, featuredCoins: featuredCoins)
    }

    private func syncView() {
        let viewItems = coins.map { coin in
            coinViewItem(coin: coin, marketInfo: marketInfos[coin.code])
        }
        view?.set(viewItems: viewItems)

        let timestamps = marketInfos.map { $0.value.timestamp }
        if let timestamp = timestamps.max() {
            view?.set(lastUpdated: Date(timeIntervalSince1970: timestamp))
        }
    }

    private func coinViewItem(coin: Coin, marketInfo: MarketInfo?) -> RateListModule.CoinViewItem {
        RateListModule.CoinViewItem(
                coinCode: coin.code,
                coinTitle: coin.title,
                blockchainType: coin.type.blockchainType,
                rate: marketInfo.map { marketInfo in
                    RateViewItem(
                            currencyValue: CurrencyValue(currency: currency, value: marketInfo.rate),
                            diff: marketInfo.diff,
                            dimmed: marketInfo.expired
                    )
                }
        )
    }

}

extension RateListPresenter: IRateListViewDelegate {

    func onLoad() {
        let featuredCoins = interactor.featuredCoins
        let activeCoins = interactor.wallets.map { $0.coin }

        coins = smartList(activeCoins: activeCoins, featuredCoins: featuredCoins)

        coins.forEach { coin in
            marketInfos[coin.code] = interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code)
        }

        syncView()

        interactor.subscribeToMarketInfos(currencyCode: currency.code)
    }

    func onSelectCoin(index: Int) {
        let coin = coins[index]

        guard marketInfos[coin.code] != nil else {
            return
        }

        router.showChart(coinCode: coin.code, coinTitle: coin.title)
    }

}

extension RateListPresenter: IRateListInteractorDelegate {

    func didReceive(marketInfos: [String: MarketInfo]) {
        self.marketInfos = marketInfos
        syncView()
        view?.refresh()
    }

}
