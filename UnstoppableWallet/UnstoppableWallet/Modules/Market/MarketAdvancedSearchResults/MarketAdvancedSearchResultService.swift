import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketAdvancedSearchResultService: IMarketMultiSortHeaderService {
    private let marketInfos: [MarketInfo]
    private let currencyKit: CurrencyKit.Kit

    private let stateRelay = PublishRelay<MarketListServiceState>()
    private(set) var state: MarketListServiceState = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncState()
        }
    }

    init(marketInfos: [MarketInfo], currencyKit: CurrencyKit.Kit) {
        self.marketInfos = marketInfos
        self.currencyKit = currencyKit

        syncState()
    }

    private func syncState() {
        state = .loaded(marketInfos: marketInfos.sorted(by: sortingField), softUpdate: false)
    }

}

extension MarketAdvancedSearchResultService: IMarketListService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
    }

}
