import Combine
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketGlobalMetricService: IMarketSingleSortHeaderService {
    typealias Item = MarketInfo

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let disposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible()
        }
    }

    private let metricsType: MarketGlobalModule.MetricsType

    let initialIndex: Int

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, metricsType: MarketGlobalModule.MetricsType) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.metricsType = metricsType
        initialIndex = metricsType.marketField.rawValue

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, currency, metricsType] in
            do {
                let marketInfos = try await marketKit.marketInfos(top: MarketModule.MarketTop.top100.rawValue, currencyCode: currency.code, apiTag: "global_metrics_\(metricsType)")
                self?.sync(marketInfos: marketInfos)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private var sortingField: MarketModule.SortingField {
        switch metricsType {
        case .volume24h: return sortDirectionAscending ? .lowestVolume : .highestVolume
        default: return sortDirectionAscending ? .lowestCap : .highestCap
        }
    }

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case let .loaded(marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: true)
    }
}

extension MarketGlobalMetricService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        syncMarketInfos()
    }
}

extension MarketGlobalMetricService: IMarketListCoinUidService {
    func coinUid(index: Int) -> String? {
        guard case let .loaded(marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }
}

extension MarketGlobalMetricService: IMarketListDecoratorService {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(index _: Int) {
        if case let .loaded(marketInfos, _, _) = state {
            state = .loaded(items: marketInfos, softUpdate: false, reorder: false)
        }
    }
}
