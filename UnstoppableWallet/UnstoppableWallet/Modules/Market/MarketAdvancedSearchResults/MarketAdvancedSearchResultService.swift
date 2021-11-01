import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketAdvancedSearchResultService: IMarketMultiSortHeaderService {
    private let marketInfos: [MarketInfo]
    private let currencyKit: CurrencyKit.Kit
    let priceChangeType: MarketModule.PriceChangeType

    private let stateRelay = PublishRelay<MarketListServiceState>()
    private(set) var state: MarketListServiceState = .loading {
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
        state = .loaded(marketInfos: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

}

extension MarketAdvancedSearchResultService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
    }

}

extension MarketAdvancedSearchResultService: IMarketListDecoratorService {

    var initialMarketField: MarketModule.MarketField {
        .price
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func onUpdate(marketField: MarketModule.MarketField) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(marketInfos: marketInfos, softUpdate: false, reorder: false))
        }
    }

}
