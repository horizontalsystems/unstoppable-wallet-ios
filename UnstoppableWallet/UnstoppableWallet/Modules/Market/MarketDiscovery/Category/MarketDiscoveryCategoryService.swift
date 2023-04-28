import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import HsToolKit
import HsExtensions

class MarketDiscoveryCategoryService: IMarketSingleSortHeaderService {
    private static let allowedTimePeriods: [HsTimePeriod] = [.day1, .week1, .month1]
    private let reachabilityDisposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private var categories = [CoinCategory]()

    @PostPublished private(set) var state: State = .loading

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var timePeriod: HsTimePeriod = MarketDiscoveryCategoryService.allowedTimePeriods[0] {
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
                        return false
                    }
                    guard let diff2 = category2.diff(timePeriod: timePeriod) else {
                        return true
                    }
                    return sortDirectionAscending ? diff < diff2 : diff > diff2
                }
                .map { category in
                    DiscoveryItem.category(category: category)
                }

        return [.topCoins] + items
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, reachabilityManager: IReachabilityManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.refresh()
                })
                .disposed(by: reachabilityDisposeBag)

        sync()
    }

    private func sync() {
        if categories.isEmpty {
            state = .loading
        }

        tasks = Set()

        Task { [weak self, marketKit, currencyKit] in
            do {
                let categories = try await marketKit.coinCategories(currencyCode: currencyKit.baseCurrency.code)
                self?.sync(categories: categories)
            } catch {
                self?.sync(error: error)
            }
        }.store(in: &tasks)
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

        state = .failed(error)
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

    func refresh() {
        if state.isEmpty {
            sync()
        }
    }

}

extension MarketDiscoveryCategoryService {

    enum DiscoveryItem {
        case topCoins
        case category(category: CoinCategory)
    }

    enum State {
        case loading
        case items([DiscoveryItem])
        case failed(Error)

        var isEmpty: Bool {
            switch self {
            case .loading: return false
            case .items(let items): return items.isEmpty
            default: return true
            }
        }

    }

}

extension MarketDiscoveryCategoryService: IMarketSingleSortHeaderDecorator {

    var allFields: [String] {
        Self.allowedTimePeriods.map { $0.title }
    }

    var currentFieldIndex: Int {
        Self.allowedTimePeriods.firstIndex(of: timePeriod) ?? 0
    }

    func setCurrentField(index: Int) {
        guard index < Self.allowedTimePeriods.count else {
            return
        }

        timePeriod = Self.allowedTimePeriods[index]
    }

}
