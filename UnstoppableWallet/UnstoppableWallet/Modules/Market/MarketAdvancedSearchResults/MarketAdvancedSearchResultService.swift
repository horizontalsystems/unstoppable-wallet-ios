import Combine
import RxSwift
import RxRelay
import MarketKit
import HsExtensions

class MarketAdvancedSearchResultService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let marketInfos: [MarketInfo]
    private let currencyManager: CurrencyManager
    let priceChangeType: MarketModule.PriceChangeType

    @PostPublished private(set) var state: MarketListServiceState<MarketInfo> = .loading

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncState(reorder: true)
        }
    }

    init(marketInfos: [MarketInfo], currencyManager: CurrencyManager, priceChangeType: MarketModule.PriceChangeType) {
        self.marketInfos = marketInfos
        self.currencyManager = currencyManager
        self.priceChangeType = priceChangeType

        syncState()
    }

    private func syncState(reorder: Bool = false) {
        state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

}

extension MarketAdvancedSearchResultService: IMarketListService {

    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
    }

}

extension MarketAdvancedSearchResultService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketAdvancedSearchResultService: IMarketListDecoratorService {

    var initialMarketFieldIndex: Int {
        0
    }

    var currency: Currency {
        currencyManager.baseCurrency
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            state = .loaded(items: marketInfos, softUpdate: false, reorder: false)
        }
    }

}
