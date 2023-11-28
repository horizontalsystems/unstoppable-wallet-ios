import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class MarketOverviewNftCollectionsViewModel {
    private let service: MarketOverviewNftCollectionsService
    private let decorator: MarketListNftCollectionDecorator
    private let disposeBag = DisposeBag()

    private let listViewItemsRelay = BehaviorRelay<[MarketModule.ListViewItem]?>(value: nil)

    init(service: MarketOverviewNftCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.collectionsObservable) { [weak self] in self?.sync(collections: $0) }

        sync(collections: service.collections)
    }

    private func sync(collections: [NftTopCollection]?) {
        listViewItemsRelay.accept(collections.map { $0.enumerated().map { decorator.listViewItem(item: NftCollectionItem(index: $0 + 1, collection: $1)) } })
    }
}

extension MarketOverviewNftCollectionsViewModel {
    var timePeriod: HsTimePeriod {
        service.timePeriod
    }

    func topCollection(uid: String) -> NftTopCollection? {
        service.topCollection(uid: uid)
    }
}

extension MarketOverviewNftCollectionsViewModel: IBaseMarketOverviewTopListViewModel {
    var listViewItemsDriver: Driver<[MarketModule.ListViewItem]?> {
        listViewItemsRelay.asDriver()
    }

    var selectorTitles: [String] {
        MarketNftTopCollectionsModule.selectorValues.map(\.title)
    }

    var selectorIndex: Int {
        MarketNftTopCollectionsModule.selectorValues.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        service.timePeriod = MarketNftTopCollectionsModule.selectorValues[selectorIndex]
    }
}
