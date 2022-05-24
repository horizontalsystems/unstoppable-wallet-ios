import RxSwift
import RxRelay

protocol IMarketMultiSortHeaderService: AnyObject {
    var marketTop: MarketModule.MarketTop { get set }
    var sortingField: MarketModule.SortingField { get set }
}

extension IMarketMultiSortHeaderService {
    var marketTop: MarketModule.MarketTop {
        get { .top100 }
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

extension MarketMultiSortHeaderViewModel: IMarketMultiSortHeaderViewModel {

    var sortItems: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }
    var sortIndex: Int {
        MarketModule.SortingField.allCases.firstIndex(of: service.sortingField) ?? 0
    }

    var leftSelectorItems: [String] {
        MarketModule.MarketTop.allCases.map { $0.title }
    }
    var leftSelectorIndex: Int {
        MarketModule.MarketTop.allCases.firstIndex(of: service.marketTop) ?? 0
    }

    var rightSelectorItems: [String] {
        MarketModule.MarketField.allCases.map { $0.title }
    }
    var rightSelectorIndex: Int {
        MarketModule.MarketField.allCases.firstIndex(of: decorator.marketField) ?? 0
    }

    func onSelectSort(index: Int) {
        service.sortingField = MarketModule.SortingField.allCases[index]
    }

    func onSelectLeft(index: Int) {
        service.marketTop = MarketModule.MarketTop.allCases[index]
    }

    func onSelectRight(index: Int) {
        decorator.marketField = MarketModule.MarketField.allCases[index]
    }

}
