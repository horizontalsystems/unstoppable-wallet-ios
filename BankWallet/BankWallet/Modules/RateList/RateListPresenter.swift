import Foundation
import XRatesKit

class RateListPresenter {
    weak var view: IRateListView?

    private let interactor: IRateListInteractor
    private let router: IRateListRouter
    private let factory: IRateListFactory

    init(interactor: IRateListInteractor, router: IRateListRouter, factory: IRateListFactory) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
    }

}

extension RateListPresenter: IRateListViewDelegate {

    func viewDidLoad() {
        let coins = interactor.coins
        let currency = interactor.currency

        var marketInfos = [CoinCode: MarketInfo]()
        coins.forEach { coin in
            marketInfos[coin.code] = interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code)
        }
        let item = factory.marketInfoViewItem(coins: coins, currency: currency, marketInfos: marketInfos)
        view?.show(item: item)

        interactor.subscribeToMarketInfos(currencyCode: currency.code)
    }

}

extension RateListPresenter: IRateListInteractorDelegate {

    func didReceive(marketInfos: [String: MarketInfo]) {
        let item = factory.marketInfoViewItem(coins: interactor.coins, currency: interactor.currency, marketInfos: marketInfos)
        view?.show(item: item)
    }

}
