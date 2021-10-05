import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketWatchlistService {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let favoritesManager: FavoritesManager
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var coinUids = [String]()
    private var marketInfos = [MarketInfo]()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, favoritesManager: FavoritesManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }

        syncCoinUids()
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids
        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if coinUids.isEmpty {
            state = .loaded(marketInfos: [])
            return
        }

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(coinUids: coinUids, order: .init(field: .marketCap, direction: .descending))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.state = .loaded(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

}

extension MarketWatchlistService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketWatchlistService {

    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

}
