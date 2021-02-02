import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketOverviewService {
    private let disposeBag = DisposeBag()
    private var topItemsDisposable: Disposable?

    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    private(set) var items = [MarketModule.Item]()

    init(currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager

        fetch()
    }

    private func fetch() {
        topItemsDisposable?.dispose()
        topItemsDisposable = nil

        stateRelay.accept(.loading)

        topItemsDisposable = rateManager.topMarketsSingle(currencyCode: currency.code)
                .subscribe(onSuccess: { [weak self] in self?.sync(items: $0) })

        topItemsDisposable?.disposed(by: disposeBag)
    }

    private func sync(items: [CoinMarket]) {
        self.items = items.enumerated().map { (index, coinMarket) in
            MarketModule.Item(coinMarket: coinMarket, score: .rank(index + 1))
        }

        stateRelay.accept(.loaded)
    }

}

extension MarketOverviewService {

    public var currency: Currency {
        //todo: refactor to use current currency and handle changing
        currencyKit.currencies.first { $0.code == "USD" } ?? currencyKit.currencies[0]
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    public func refresh() {
        fetch()
    }

}

extension MarketOverviewService {

    enum State {
        case loaded
        case loading
        case error(error: Error)
    }

}
