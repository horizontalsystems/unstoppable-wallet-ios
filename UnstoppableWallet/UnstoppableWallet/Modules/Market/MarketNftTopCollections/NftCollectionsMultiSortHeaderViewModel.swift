import MarketKit

class NftCollectionsMultiSortHeaderViewModel {
    private let service: MarketNftTopCollectionsService
    private let decorator: MarketListNftCollectionDecorator

    init(service: MarketNftTopCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator
    }
}

extension NftCollectionsMultiSortHeaderViewModel: IMarketMultiSortHeaderViewModel {
    var sortItems: [String] {
        MarketNftTopCollectionsModule.SortType.allCases.map(\.title)
    }

    var sortIndex: Int {
        MarketNftTopCollectionsModule.SortType.allCases.firstIndex(of: service.sortType) ?? 0
    }

    var leftSelectorItems: [String] {
        []
    }

    var leftSelectorIndex: Int {
        0
    }

    var rightSelectorItems: [String] {
        MarketNftTopCollectionsModule.selectorValues.map(\.title)
    }

    var rightSelectorIndex: Int {
        MarketNftTopCollectionsModule.selectorValues.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelectSort(index: Int) {
        service.sortType = MarketNftTopCollectionsModule.SortType.allCases[index]
    }

    func onSelectLeft(index _: Int) {}

    func onSelectRight(index: Int) {
        service.timePeriod = MarketNftTopCollectionsModule.selectorValues[index]
    }
}
