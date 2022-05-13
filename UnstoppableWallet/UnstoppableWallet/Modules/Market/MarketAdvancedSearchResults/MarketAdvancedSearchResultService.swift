import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketAdvancedSearchResultService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let marketInfos: [MarketInfo]
    private let currencyKit: CurrencyKit.Kit
    let priceChangeType: MarketModule.PriceChangeType

    private let stateRelay = PublishRelay<MarketListServiceState<MarketInfo>>()
    private(set) var state: MarketListServiceState<MarketInfo> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncState(reorder: true)
        }
    }

    init(marketInfos: [MarketInfo], currencyKit: CurrencyKit.Kit, priceChangeType: MarketModule.PriceChangeType) {
        self.marketInfos = marketInfos
        self.currencyKit = currencyKit
        self.priceChangeType = priceChangeType

        syncState()
    }

    private func syncState(reorder: Bool = false) {
        state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

}

extension MarketAdvancedSearchResultService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
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
        currencyKit.baseCurrency
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(items: marketInfos, softUpdate: false, reorder: false))
        }
    }

}
