import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketDiscoveryCategoryService {
    private var disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private var categories = [CoinCategory]()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var timePeriod: HsTimePeriod = .day1 {
        didSet {
            if oldValue != timePeriod {
                updateSortParameters()
            }
        }
    }

    public var sortDirectionAscending: Bool = false {
        didSet {
            if oldValue != sortDirectionAscending {
                updateSortParameters()
            }
        }
    }

    private var sortedItems: [DiscoveryItem] {
        let items = categories
                .sorted { category, category2 in
                    guard let diff = category.diff(timePeriod: timePeriod) else {
                        return sortDirectionAscending
                    }
                    guard let diff2 = category2.diff(timePeriod: timePeriod) else {
                        return !sortDirectionAscending
                    }
                    return sortDirectionAscending ? diff < diff2 : diff > diff2
                }
                .map { category in
                    DiscoveryItem.category(category: Item(category: category, timePeriod: timePeriod))
                }

        return [.topCoins] + items
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        sync()
    }

    private func sync() {
        if categories.isEmpty {
            self.state = .loading
        }

        disposeBag = DisposeBag()

        marketKit.coinCategoriesSingle(currencyCode: currencyKit.baseCurrency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] categories in
                    self?.sync(categories: categories)
                }, onError: { error in
                    self.sync(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func sync(categories: [CoinCategory]) {
        self.categories = categories

        state = .items(sortedItems)
    }

    private func sync(error: Error) {

        // Try to get fallback from storage if categories empty yet, or return last items
        guard categories.isEmpty else {
            state = .items(sortedItems)

            return
        }

        let syncedCategories = (try? marketKit.coinCategories()) ?? []
        categories = syncedCategories

        if syncedCategories.isEmpty {
            state = .failed(error)
        } else {
            state = .fallbackItems(sortedItems)
        }
    }

    private func updateSortParameters() {
        if state.isEmpty {
            sync()
            return
        }

        switch state {
        case .items: state = .items(sortedItems)
        default: ()
        }
    }

}

extension MarketDiscoveryCategoryService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension MarketDiscoveryCategoryService {

    enum DiscoveryItem {
        case topCoins
        case category(category: Item)
    }

    enum State {
        case loading
        case items([DiscoveryItem])
        case fallbackItems([DiscoveryItem])
        case failed(Error)

        var isEmpty: Bool {
            switch self {
            case .loading: return false
            case .items(let items): return items.isEmpty
            case .fallbackItems(let items): return items.isEmpty
            default: return true
            }
        }

    }

    struct Item {
        let uid: String
        let name: String
        let imageUrl: String
        let descriptions: [String: String]
        let marketCap: Decimal?
        let diff: Decimal?

        init(category: CoinCategory, timePeriod: HsTimePeriod) {
            uid = category.uid
            name = category.name
            imageUrl = category.imageUrl
            descriptions = category.descriptions
            marketCap = category.marketCap
            diff = category.diff(timePeriod: timePeriod)
        }

    }


}
