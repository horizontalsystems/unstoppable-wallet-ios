import CurrencyKit
import XRatesKit
import RxSwift
import RxRelay

class MarketWatchlistService {
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager
    private let favoritesManager: IFavoritesManager

    private let disposeBag = DisposeBag()
    private var marketsDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var items = [MarketModule.Item]()

    init(currencyKit: ICurrencyKit, rateManager: IRateManager, favoritesManager: IFavoritesManager) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.dataUpdatedObservable) { [weak self] in
            self?.fetch()
        }

        fetch()
    }

    private func fetch() {
        marketsDisposeBag = DisposeBag()

        state = .loading

        let coinCodes = favoritesManager.all.map { $0.coinCode }
        rateManager.coinsMarketSingle(currencyCode: currency.code, coinCodes: coinCodes)
                .subscribe(onSuccess: { [weak self] coinMarkets in
                    self?.onFetchSuccess(coinMarkets: coinMarkets)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: marketsDisposeBag)
    }

    private func onFetchSuccess(coinMarkets: [CoinMarket]) {
        items = coinMarkets.map { coinMarket in
            MarketModule.Item(coinMarket: coinMarket)
        }

        state = .loaded
    }

    private func onFetchFailed(error: Error) {
        state = .failed(error: error)
    }

}

extension MarketWatchlistService {

    var currency: Currency {
        //todo: refactor to use current currency and handle changing
        currencyKit.currencies.first { $0.code == "USD" } ?? currencyKit.currencies[0]
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}

extension MarketWatchlistService {

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}
