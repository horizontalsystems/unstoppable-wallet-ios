protocol IMarketMultiSortHeaderService: AnyObject {
    var sortingField: MarketModule.SortingField { get set }
    var marketField: MarketModule.MarketField { get set }
}

class MarketMultiSortHeaderViewModel {
    private let service: IMarketMultiSortHeaderService

    init(service: IMarketMultiSortHeaderService) {
        self.service = service
    }

}

extension MarketMultiSortHeaderViewModel {

    var sortingFields: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }

    var marketFields: [String] {
        MarketModule.MarketField.allCases.map { $0.title }
    }

    var sortingFieldIndex: Int {
        MarketModule.SortingField.allCases.firstIndex(of: service.sortingField) ?? 0
    }

    var marketFieldIndex: Int {
        MarketModule.MarketField.allCases.firstIndex(of: service.marketField) ?? 0
    }

    func onSelectSortingField(index: Int) {
        service.sortingField = MarketModule.SortingField.allCases[index]
    }

    func onSelectMarketField(index: Int) {
        service.marketField = MarketModule.MarketField.allCases[index]
    }

}
