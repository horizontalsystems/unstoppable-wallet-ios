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
    private let decorator: MarketListMarketFieldDecorator

    init(service: IMarketMultiSortHeaderService, decorator: MarketListMarketFieldDecorator) {
        self.service = service
        self.decorator = decorator
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
        MarketModule.MarketField.allCases.firstIndex(of: decorator.marketField) ?? 0
    }

    func onSelectMarketTop(index: Int) {
        service.marketTop = MarketModule.MarketTop.allCases[index]
    }

    func onSelectSortingField(index: Int) {
        service.sortingField = MarketModule.SortingField.allCases[index]
    }

    func onSelectMarketField(index: Int) {
        decorator.marketField = MarketModule.MarketField.allCases[index]
    }

}
