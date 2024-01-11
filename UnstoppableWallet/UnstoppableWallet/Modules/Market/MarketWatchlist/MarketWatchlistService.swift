import Combine
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketWatchlistService: IMarketSingleSortHeaderService {
    typealias Item = MarketInfo

    private let keySortDirectionField = "market-watchlist-sort-direction-field"
    private let keyPriceChangeField = "market-watchlist-price-change-field"

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let favoritesManager: FavoritesManager
    private let appManager: IAppManager
    private let userDefaultsStorage: UserDefaultsStorage
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    private var coinUids = [String]()

    var sortDirectionAscending: Bool {
        didSet {
            userDefaultsStorage.set(value: sortDirectionAscending, for: keySortDirectionField)
            syncIfPossible()
        }
    }

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, favoritesManager: FavoritesManager, appManager: IAppManager, userDefaultsStorage: UserDefaultsStorage) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.favoritesManager = favoritesManager
        self.appManager = appManager
        self.userDefaultsStorage = userDefaultsStorage

        sortDirectionAscending = userDefaultsStorage.value(for: keySortDirectionField) ?? false
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids

        if case let .loaded(marketInfos, _, _) = state {
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
        tasks = Set()

        if coinUids.isEmpty {
            state = .loaded(items: [], softUpdate: false, reorder: false)
            return
        }

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coinUids, currency] in
            do {
                let marketInfos = try await marketKit.marketInfos(coinUids: coinUids, currencyCode: currency.code, apiTag: "watchlist")
                self?.sync(marketInfos: marketInfos)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        let sortingField: MarketModule.SortingField = sortDirectionAscending ? .topLosers : .topGainers
        state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case let .loaded(marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: true)
    }
}

extension MarketWatchlistService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncMarketInfos()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncMarketInfos() }

        syncCoinUids()
    }

    func refresh() {
        syncMarketInfos()
    }
}

extension MarketWatchlistService: IMarketListCoinUidService {
    func coinUid(index: Int) -> String? {
        guard case let .loaded(marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }
}

extension MarketWatchlistService: IMarketListDecoratorService {
    var initialIndex: Int {
        userDefaultsStorage.value(for: keyPriceChangeField) ?? 0
    }

    var currency: Currency {
        currencyManager.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        MarketModule.PriceChangeType.sortingTypes.at(index: initialIndex) ?? .day
    }

    func onUpdate(index: Int) {
        userDefaultsStorage.set(value: index, for: keyPriceChangeField)

        syncIfPossible()
    }
}
