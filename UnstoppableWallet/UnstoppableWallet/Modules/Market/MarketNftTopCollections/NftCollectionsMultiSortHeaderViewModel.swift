class NftCollectionsMultiSortHeaderViewModel {
    private let service: IMarketMultiSortHeaderService
    private let decorator: MarketListNftCollectionDecorator

    init(service: IMarketMultiSortHeaderService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator
    }

}

extension NftCollectionsMultiSortHeaderViewModel: IMarketMultiSortHeaderViewModel {

    var marketTops: [String] {
        []
    }

    var sortingFields: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }

    var marketFields: [String] {
        MarketModule.NftMarketField.allCases.map { $0.title }
    }

    var marketTopIndex: Int {
        0
    }

    var sortingFieldIndex: Int {
        MarketModule.SortingField.allCases.firstIndex(of: service.sortingField) ?? 0
    }

    var marketFieldIndex: Int {
        MarketModule.NftMarketField.allCases.firstIndex(of: decorator.marketField) ?? 0
    }

    func onSelectMarketTop(index: Int) {
    }

    func onSelectSortingField(index: Int) {
        service.sortingField = MarketModule.SortingField.allCases[index]
    }

    func onSelectMarketField(index: Int) {
        decorator.marketField = MarketModule.NftMarketField.allCases[index]
    }

}
