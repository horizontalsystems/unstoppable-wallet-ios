import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketOverviewService {
    private var disposeBag = DisposeBag()
    private var topMarketsDisposeBag = DisposeBag()

    private let currencyKit: CurrencyKit.Kit
    private let appManager: IAppManager
    private let rateManager: IRateManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var items = [MarketModule.Item]()

    init(currencyKit: CurrencyKit.Kit, appManager: IAppManager, rateManager: IRateManager) {
        self.currencyKit = currencyKit
        self.appManager = appManager
        self.rateManager = rateManager

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in
            self?.items = []
            self?.fetch()
        }

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.fetch() }
        fetch()
    }

    private func fetch() {
        topMarketsDisposeBag = DisposeBag()

        state = .loading

        rateManager.topMarketsSingle(currencyCode: currencyKit.baseCurrency.code, fetchDiffPeriod: .hour24, itemCount: 250)
                .subscribe(onSuccess: { [weak self] in
                    self?.onFetchSuccess(items: $0)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: topMarketsDisposeBag)
    }

    private func onFetchSuccess(items: [CoinMarket]) {
        self.items = items.map { MarketModule.Item(coinMarket: $0) }

        state = .loaded
    }

    private func onFetchFailed(error: Error) {
        items = []
        state = .failed(error: error)
    }

}

extension MarketOverviewService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}

extension MarketOverviewService {

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}
