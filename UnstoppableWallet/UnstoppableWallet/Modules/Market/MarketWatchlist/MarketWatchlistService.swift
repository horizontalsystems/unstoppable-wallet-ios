import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import StorageKit

class MarketWatchlistService: IMarketMultiSortHeaderService {
    private let keySortingField = "market-watchlist-sorting-field"
    private let keyMarketField = "market-watchlist-market-field"

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let favoritesManager: FavoritesManager
    private let storage: StorageKit.ILocalStorage
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState>()
    private(set) var state: MarketListServiceState = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortingField: MarketModule.SortingField {
        didSet {
            syncIfPossible()
            storage.set(value: sortingField.rawValue, for: keySortingField)
        }
    }

    private var coinUids = [String]()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, favoritesManager: FavoritesManager, storage: StorageKit.ILocalStorage) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.favoritesManager = favoritesManager
        self.storage = storage

        if let rawValue: Int = storage.value(for: keySortingField), let sortingField = MarketModule.SortingField(rawValue: rawValue) {
            self.sortingField = sortingField
        } else {
            sortingField = .highestCap
        }

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }

        syncCoinUids()
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids

        if case .loaded(let marketInfos, _, _) = state {
            let newMarketInfos = marketInfos.filter { marketInfo in
                coinUids.contains(marketInfo.fullCoin.coin.uid)
            }

            if newMarketInfos.count == coinUids.count {
                state = .loaded(marketInfos: newMarketInfos, softUpdate: true, reorder: false)
                return
            }
        }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if coinUids.isEmpty {
            state = .loaded(marketInfos: [], softUpdate: false, reorder: false)
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

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        state = .loaded(marketInfos: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: true)
    }

}

extension MarketWatchlistService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketWatchlistService: IMarketListDecoratorService {

    var initialMarketField: MarketModule.MarketField {
        if let rawValue: Int = storage.value(for: keyMarketField), let marketField = MarketModule.MarketField(rawValue: rawValue) {
            return marketField
        }

        return .price
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketField: MarketModule.MarketField) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(marketInfos: marketInfos, softUpdate: false, reorder: false))
        }

        storage.set(value: marketField.rawValue, for: keyMarketField)
    }

}
