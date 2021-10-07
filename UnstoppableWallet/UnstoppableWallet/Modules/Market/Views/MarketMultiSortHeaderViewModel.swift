import RxSwift
import RxRelay

protocol IMarketMultiSortHeaderService: AnyObject {
    var marketTop: MarketModule.MarketTop { get set }
    var sortingField: MarketModule.SortingField { get set }
}

extension IMarketMultiSortHeaderService {
    var marketTop: MarketModule.MarketTop {
        get { .top250 }
        set {}
    }
}

class MarketMultiSortHeaderViewModel {
    private let service: IMarketMultiSortHeaderService

    private let marketFieldRelay = PublishRelay<MarketModule.MarketField>()
    var marketField: MarketModule.MarketField = .price {
        didSet {
            marketFieldRelay.accept(marketField)
        }
    }

    init(service: IMarketMultiSortHeaderService) {
        self.service = service
    }

}

extension MarketMultiSortHeaderViewModel: IMarketFieldDataSource {

    var marketFieldObservable: Observable<MarketModule.MarketField> {
        marketFieldRelay.asObservable()
    }

}

extension MarketMultiSortHeaderViewModel {

    var marketTops: [String] {
        MarketModule.MarketTop.allCases.map { $0.title }
    }

    var sortingFields: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }

    var marketFields: [String] {
        MarketModule.MarketField.allCases.map { $0.title }
    }

    var marketTopIndex: Int {
        MarketModule.MarketTop.allCases.firstIndex(of: service.marketTop) ?? 0
    }

    var sortingFieldIndex: Int {
        MarketModule.SortingField.allCases.firstIndex(of: service.sortingField) ?? 0
    }

    var marketFieldIndex: Int {
        MarketModule.MarketField.allCases.firstIndex(of: marketField) ?? 0
    }

    func onSelectMarketTop(index: Int) {
        service.marketTop = MarketModule.MarketTop.allCases[index]
    }

    func onSelectSortingField(index: Int) {
        service.sortingField = MarketModule.SortingField.allCases[index]
    }

    func onSelectMarketField(index: Int) {
        marketField = MarketModule.MarketField.allCases[index]
    }

}
