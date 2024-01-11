import Combine
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketGlobalDefiMetricService: IMarketSingleSortHeaderService {
    typealias Item = DefiItem

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let disposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<DefiItem> = .loading

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible()
        }
    }

    let initialIndex: Int = 1

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let marketInfos = try await marketKit.marketInfos(top: MarketModule.MarketTop.top100.rawValue, currencyCode: currency.code, defi: true, apiTag: "global_metrics_defi_cap")

                let rankedItems = marketInfos.enumerated().map { index, info in
                    Item(marketInfo: info, tvlRank: index + 1)
                }

                self?.sync(items: rankedItems)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func sync(items: [Item], reorder: Bool = false) {
        state = .loaded(items: sorted(items: items), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case let .loaded(items, _, _) = state else {
            return
        }

        sync(items: items, reorder: true)
    }

    func sorted(items: [Item]) -> [Item] {
        items.sorted { lhsItem, rhsItem in
            if sortDirectionAscending {
                return lhsItem.tvlRank > rhsItem.tvlRank
            } else {
                return lhsItem.tvlRank < rhsItem.tvlRank
            }
        }
    }
}

extension MarketGlobalDefiMetricService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        syncMarketInfos()
    }
}

extension MarketGlobalDefiMetricService: IMarketListCoinUidService {
    func coinUid(index: Int) -> String? {
        guard case let .loaded(items, _, _) = state, index < items.count else {
            return nil
        }

        return items[index].marketInfo.fullCoin.coin.uid
    }
}

extension MarketGlobalDefiMetricService: IMarketListDecoratorService {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(index _: Int) {
        if case let .loaded(items, _, _) = state {
            state = .loaded(items: items, softUpdate: false, reorder: false)
        }
    }
}

extension MarketGlobalDefiMetricService {
    struct DefiItem {
        let marketInfo: MarketInfo
        let tvlRank: Int
    }
}
