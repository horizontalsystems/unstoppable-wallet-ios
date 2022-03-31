import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketDiscoveryService {
    private let disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let favoritesManager: FavoritesManager

    private var discoveryItems = [DiscoveryItem]()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .discovery(items: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var diffTimeframe: DiffTimeframe = .day {
        didSet {
            syncDiscoveryItems()

            if case .discovery = state {
                state = .discovery(items: discoveryItems)
            }
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, favoritesManager: FavoritesManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.favoritesManager = favoritesManager

        subscribe(disposeBag, marketKit.coinCategoriesObservable) { [weak self] _ in self?.syncDiscoveryItems() }

        syncDiscoveryItems()
        syncDiscoveryMarketData()

        state = .discovery(items: discoveryItems)
    }

    private func syncDiscoveryItems() {
        var discoveryItems: [DiscoveryItem] = [.topCoins]

        do {
            for coinCategory in try marketKit.coinCategories() {
                discoveryItems.append(.category(category: Category(coinCategory: coinCategory)))
            }
        } catch {
            // do nothing
        }

        self.discoveryItems = discoveryItems
    }

    private func coinUid(index: Int) -> String? {
        guard case .searchResults(let fullCoins) = state, index < fullCoins.count else {
            return nil
        }

        return fullCoins[index].coin.uid
    }

    private func syncDiscoveryMarketData() {
        marketKit.categoriesMarketDataSingle(currencyCode: currencyKit.baseCurrency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] categoriesMarketData in
                    self?.processMarketData(discoveryMarketData: categoriesMarketData)
                })
                .disposed(by: disposeBag)
    }

    private func processMarketData(discoveryMarketData: [CoinCategoryMarketData]) {
        var discoveryItems: [DiscoveryItem] = [.topCoins]

        for item in self.discoveryItems {
            if case let .category(category) = item, let marketData = (discoveryMarketData.first { $0.uid == category.uid }) {
                discoveryItems.append(.category(category: Category(category: category, marketData: marketData, diffTimeframe: diffTimeframe)))
            }
        }

        self.discoveryItems = discoveryItems

        if case .discovery = state {
            state = .discovery(items: discoveryItems)
        }
    }

}

extension MarketDiscoveryService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(filter: String) {
        if filter.isEmpty {
            state = .discovery(items: discoveryItems)
        } else {
            do {
                state = .searchResults(fullCoins: try marketKit.fullCoins(filter: filter))
            } catch {
                state = .searchResults(fullCoins: [])
            }
        }
    }

    func isFavorite(index: Int) -> Bool {
        guard let coinUid = coinUid(index: index) else {
            return false
        }

        return favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            return
        }

        favoritesManager.add(coinUid: coinUid)
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            return
        }

        favoritesManager.remove(coinUid: coinUid)
    }

}

extension MarketDiscoveryService {

    enum State {
        case discovery(items: [DiscoveryItem])
        case searchResults(fullCoins: [FullCoin])
    }

    enum DiscoveryItem {
        case topCoins
        case category(category: Category)
    }

    struct Category {
        let uid: String
        let name: String
        let imageUrl: String
        let descriptions: [String: String]
        let order: Int
        let marketCap: Decimal?
        let diff: Decimal?

        init(coinCategory: CoinCategory) {
            uid = coinCategory.uid
            name = coinCategory.name
            imageUrl = coinCategory.imageUrl
            descriptions = coinCategory.descriptions
            order = coinCategory.order
            marketCap = nil
            diff = nil
        }

        init(category: Category, marketData: CoinCategoryMarketData, diffTimeframe: DiffTimeframe) {
            uid = category.uid
            name = category.name
            imageUrl = category.imageUrl
            descriptions = category.descriptions
            order = category.order

            marketCap = marketData.marketCap
            diff = diffTimeframe.diff(coinCategory: marketData)
        }

    }

    enum DiffTimeframe {
        case day
        case week
        case month

        func diff(coinCategory: CoinCategoryMarketData) -> Decimal? {
            switch self {
            case .day: return coinCategory.diff24H
            case .week: return coinCategory.diff1W
            case .month: return coinCategory.diff1M
            }
        }

    }

}
