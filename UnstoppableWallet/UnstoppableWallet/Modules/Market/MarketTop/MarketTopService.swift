import Combine
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketTopService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let disposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    var marketTop: MarketModule.MarketTop {
        didSet {
            syncIfPossible()
        }
    }

    var sortingField: MarketModule.SortingField {
        didSet {
            syncIfPossible()
        }
    }

    let initialIndex: Int
    private let apiTag: String

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, marketTop: MarketModule.MarketTop, sortingField: MarketModule.SortingField, marketField: MarketModule.MarketField) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.marketTop = marketTop
        self.sortingField = sortingField
        initialIndex = marketField.rawValue

        apiTag = "market_top_\(marketTop.rawValue)_\(sortingField.raw)_\(marketField.raw)"

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        if case .failed = state {
            internalState = .loading
        }

        Task { [weak self, marketKit, currency, apiTag] in
            do {
                let marketInfos = try await marketKit.marketInfos(top: 1000, currencyCode: currency.code, apiTag: apiTag)
                self?.internalState = .loaded(marketInfos: marketInfos)
            } catch {
                self?.internalState = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func syncState(reorder: Bool = false) {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos):
            let marketInfos: [MarketInfo] = Array(marketInfos.prefix(marketTop.rawValue))
            state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
        case let .failed(error):
            state = .failed(error: error)
        }
    }

    private func syncIfPossible() {
        guard case .loaded = internalState else {
            return
        }

        syncState(reorder: true)
    }
}

extension MarketTopService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        syncMarketInfos()
    }
}

extension MarketTopService: IMarketListCoinUidService {
    func coinUid(index: Int) -> String? {
        guard case let .loaded(marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }
}

extension MarketTopService: IMarketListDecoratorService {
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

extension MarketTopService {
    private enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }
}
