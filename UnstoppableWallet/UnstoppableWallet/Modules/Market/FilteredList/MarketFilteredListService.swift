import Combine
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import HsExtensions

protocol IMarketFilteredListProvider {
    func marketInfo(currencyCode: String) async throws -> [MarketInfo]
}

class MarketFilteredListService: IMarketMultiSortHeaderService {
    private let currencyKit: CurrencyKit.Kit
    private let provider: IMarketFilteredListProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncIfPossible()
        }
    }

    init(currencyKit: CurrencyKit.Kit, provider: IMarketFilteredListProvider) {
        self.currencyKit = currencyKit
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
                let marketInfos = try await provider.marketInfo(currencyCode: currency.code)
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
        guard case .loaded(let marketInfos, _, _) = state else {
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
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketFilteredListService: IMarketListDecoratorService {

    var initialMarketFieldIndex: Int {
        0
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            state = .loaded(items: marketInfos, softUpdate: false, reorder: false)
        }
    }

}
