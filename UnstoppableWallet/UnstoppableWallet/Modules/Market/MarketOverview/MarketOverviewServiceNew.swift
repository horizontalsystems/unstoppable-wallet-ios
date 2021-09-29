import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay
import MarketKit

class MarketOverviewServiceNew {
    private var disposeBag = DisposeBag()
    private var topMarketsDisposeBag = DisposeBag()

    private let currencyKit: CurrencyKit.Kit
    private let appManager: IAppManager
    private let marketKit: MarketKit.Kit

    private(set) var topMarket: Int = 250
    private let limit: Int
    private let order: MarketKit.MarketInfo.Order

    private let topMarketRelay = PublishRelay<State>()
    private(set) var topMarketState: State = .loading {
        didSet {
            topMarketRelay.accept(topMarketState)
        }
    }

    private(set) var items = [MarketModule.Item]()

    init(overviewType: RateManager.OverviewType, currencyKit: CurrencyKit.Kit, appManager: IAppManager, marketKit: MarketKit.Kit) {
        self.currencyKit = currencyKit
        self.appManager = appManager
        self.marketKit = marketKit

        switch overviewType {
        case .gainers(let count):
            limit = count
            order = MarketKit.MarketInfo.Order(field: .priceChange, direction: .descending)
        case .losers(let count):
            limit = count
            order = MarketKit.MarketInfo.Order(field: .priceChange, direction: .ascending)
        }

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in
            self?.items = []
            self?.fetchTopMarket()
        }

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.fetchTopMarket() }
        fetchTopMarket()
    }

    private func fetchTopMarket() {
        topMarketsDisposeBag = DisposeBag()

        topMarketState = .loading

        marketKit.marketInfosSingle(top: topMarket, limit: limit, order: order)
                .subscribe(onSuccess: { [weak self] in
                    self?.onFetchSuccess(items: $0)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: topMarketsDisposeBag)
    }

    private func onFetchSuccess(items: [MarketKit.MarketInfo]) {
        self.items = items.map { MarketModule.Item(marketInfo: $0) }

        topMarketState = .loaded
    }

    private func onFetchFailed(error: Error) {
        items = []
        topMarketState = .failed(error: error)
    }

}

extension MarketOverviewServiceNew {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<State> {
        topMarketRelay.asObservable()
    }

    func refresh() {
        fetchTopMarket()
    }

    func set(topMarketLimit: Int) {
        guard topMarketLimit != self.topMarket else {
            return
        }

        self.topMarket = topMarketLimit
        fetchTopMarket()
    }

}

extension MarketOverviewServiceNew {

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}
