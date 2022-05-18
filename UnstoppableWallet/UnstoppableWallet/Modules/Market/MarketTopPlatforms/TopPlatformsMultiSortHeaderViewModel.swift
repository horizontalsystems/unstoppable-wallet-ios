import MarketKit

class TopPlatformsMultiSortHeaderViewModel {
    private let service: MarketTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator

    init(service: MarketTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator
    }

}

extension TopPlatformsMultiSortHeaderViewModel: IMarketMultiSortHeaderViewModel {

    var sortItems: [String] {
        MarketTopPlatformsModule.SortType.allCases.map { $0.title }
    }
    var sortIndex: Int {
        MarketTopPlatformsModule.SortType.allCases.firstIndex(of: service.sortType) ?? 0
    }

    var leftSelectorItems: [String] {
        []
    }
    var leftSelectorIndex: Int {
        0
    }

    var rightSelectorItems: [String] {
        MarketTopPlatformsModule.selectorValues.map { $0.title }
    }
    var rightSelectorIndex: Int {
        MarketTopPlatformsModule.selectorValues.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelectSort(index: Int) {
        service.sortType = MarketTopPlatformsModule.SortType.allCases[index]
    }

    func onSelectLeft(index: Int) {
    }

    func onSelectRight(index: Int) {
        service.timePeriod = MarketTopPlatformsModule.selectorValues[index]
    }

}
