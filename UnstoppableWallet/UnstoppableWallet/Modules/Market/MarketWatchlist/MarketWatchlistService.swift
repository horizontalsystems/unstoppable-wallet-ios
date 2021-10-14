import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketWatchlistService: IMarketMultiSortHeaderService {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let favoritesManager: FavoritesManager
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState>()
    private(set) var state: MarketListServiceState = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncIfPossible()
        }
    }

    private var coinUids = [String]()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, favoritesManager: FavoritesManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }

        syncCoinUids()
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids

        if case .loaded(let marketInfos, _) = state {
            let newMarketInfos = marketInfos.filter { marketInfo in
                coinUids.contains(marketInfo.fullCoin.coin.uid)
            }

            if newMarketInfos.count == coinUids.count {
                state = .loaded(marketInfos: newMarketInfos, softUpdate: true)
                return
            }
        }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if coinUids.isEmpty {
            state = .loaded(marketInfos: [], softUpdate: false)
            return
        }

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(coinUids: coinUids)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.sync(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func sync(marketInfos: [MarketInfo]) {
        state = .loaded(marketInfos: marketInfos.sorted(by: sortingField), softUpdate: false)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _) = state else {
            return
        }

        sync(marketInfos: marketInfos)
    }

}

extension MarketWatchlistService: IMarketListService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}
