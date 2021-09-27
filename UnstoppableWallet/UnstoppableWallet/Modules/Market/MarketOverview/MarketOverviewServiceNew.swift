import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketOverviewServiceNew {
    private var disposeBag = DisposeBag()
    private var topMarketsDisposeBag = DisposeBag()

    private let currencyKit: CurrencyKit.Kit
    private let appManager: IAppManager
    private let rateManager: IRateManager

    private(set) var topMarketLimit: Int = 250
    private let overviewType: RateManager.OverviewType

    private let topMarketRelay = PublishRelay<State>()
    private(set) var topMarketState: State = .loading {
        didSet {
            topMarketRelay.accept(topMarketState)
        }
    }

    private(set) var items = [MarketModule.Item]()

    init(overviewType: RateManager.OverviewType, currencyKit: CurrencyKit.Kit, appManager: IAppManager, rateManager: IRateManager) {
        self.overviewType = overviewType
        self.currencyKit = currencyKit
        self.appManager = appManager
        self.rateManager = rateManager

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

        rateManager.overviewTopMarketsSingle(type: overviewType, currencyCode: currencyKit.baseCurrency.code, fetchDiffPeriod: .hour24, itemCount: topMarketLimit)
                .subscribe(onSuccess: { [weak self] in
                    self?.onFetchSuccess(items: $0)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: topMarketsDisposeBag)
    }

    private func onFetchSuccess(items: [CoinMarket]) {
        self.items = items.enumerated().map { (index, coinMarket) in
            MarketModule.Item(coinMarket: coinMarket, score: .rank(index + 1))
        }

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
        guard topMarketLimit != self.topMarketLimit else {
            return
        }

        self.topMarketLimit = topMarketLimit
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
