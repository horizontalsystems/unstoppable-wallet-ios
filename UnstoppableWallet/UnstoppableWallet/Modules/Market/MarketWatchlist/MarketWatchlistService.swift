import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketWatchlistService {
    private let disposeBag = DisposeBag()
    private var itemsDisposable: Disposable?

    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager
    private let favoritesManager: IFavoritesManager

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    private(set) var items = [MarketModule.Item]()

    init(currencyKit: ICurrencyKit, rateManager: IRateManager, favoritesManager: IFavoritesManager) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.favoritesManager = favoritesManager

        fetch()
        subscribe(disposeBag, favoritesManager.dataUpdatedObservable) { [weak self] in
            self?.fetch()
        }
    }

    private func fetch() {
        itemsDisposable?.dispose()
        itemsDisposable = nil

        stateRelay.accept(.loading)

        let coinCodes = favoritesManager.all.map { $0.coinCode }
        itemsDisposable = rateManager.coinsMarketSingle(currencyCode: currency.code, coinCodes: coinCodes)
                .subscribe(onSuccess: { [weak self] in self?.sync(items: $0) })

        itemsDisposable?.disposed(by: disposeBag)
    }

    private func sync(items: [CoinMarket]) {
        self.items = items.map { coinMarket in
            MarketModule.Item(coinMarket: coinMarket)
        }

        stateRelay.accept(.loaded)
    }

}

extension MarketWatchlistService {

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

extension MarketWatchlistService {

    enum State {
        case loaded
        case loading
        case error(error: Error)
    }

}
