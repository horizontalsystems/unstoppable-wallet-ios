import Combine
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

protocol IMarketFilteredListProvider {
    func marketInfos(currencyCode: String) async throws -> [MarketInfo]
}

class MarketFilteredListService: IMarketMultiSortHeaderService {
    private let currencyManager: CurrencyManager
    private let provider: IMarketFilteredListProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncIfPossible()
        }
    }

    init(currencyManager: CurrencyManager, provider: IMarketFilteredListProvider) {
        self.currencyManager = currencyManager
        self.provider = provider

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, provider, currency] in
            do {
                let marketInfos = try await provider.marketInfos(currencyCode: currency.code)
                self?.sync(marketInfos: marketInfos)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
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

extension MarketFilteredListService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<MarketInfo>, Never> {
        $state
    }

    func refresh() {
        syncMarketInfos()
    }
}

extension MarketFilteredListService: IMarketListCoinUidService {
    func coinUid(index: Int) -> String? {
        guard case let .loaded(marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }
}

extension MarketFilteredListService: IMarketListDecoratorService {
    var initialIndex: Int {
        0
    }

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
