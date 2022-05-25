import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import StorageKit

class MarketWatchlistService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let keySortingField = "market-watchlist-sorting-field"
    private let keyMarketField = "market-watchlist-market-field"

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let favoritesManager: FavoritesManager
    private let appManager: IAppManager
    private let storage: StorageKit.ILocalStorage
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState<MarketInfo>>()
    private(set) var state: MarketListServiceState<MarketInfo> = .loading {
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

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, favoritesManager: FavoritesManager, appManager: IAppManager, storage: StorageKit.ILocalStorage) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.favoritesManager = favoritesManager
        self.appManager = appManager
        self.storage = storage

        if let rawValue: Int = storage.value(for: keySortingField), let sortingField = MarketModule.SortingField(rawValue: rawValue) {
            self.sortingField = sortingField
        } else {
            sortingField = .highestCap
        }
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids

        if case .loaded(let marketInfos, _, _) = state {
            let newMarketInfos = marketInfos.filter { marketInfo in
                coinUids.contains(marketInfo.fullCoin.coin.uid)
            }

            if newMarketInfos.count == coinUids.count {
                state = .loaded(items: newMarketInfos, softUpdate: true, reorder: false)
                return
            }
        }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if coinUids.isEmpty {
            state = .loaded(items: [], softUpdate: false, reorder: false)
            return
        }

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(coinUids: coinUids, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.sync(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: true)
    }

}

extension MarketWatchlistService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
    }

    func load() {
        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }
        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in self?.syncMarketInfos() }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncMarketInfos() }

        syncCoinUids()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketWatchlistService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketWatchlistService: IMarketListDecoratorService {

    var initialMarketFieldIndex: Int {
        storage.value(for: keyMarketField) ?? 0
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(items: marketInfos, softUpdate: false, reorder: false))
        }

        storage.set(value: marketFieldIndex, for: keyMarketField)
    }

}
