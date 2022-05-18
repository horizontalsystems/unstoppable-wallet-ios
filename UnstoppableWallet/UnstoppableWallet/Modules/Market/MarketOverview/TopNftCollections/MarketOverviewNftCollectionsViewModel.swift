import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewNftCollectionsViewModel {
    private let listCount = 5

    private let service: MarketNftTopCollectionsService
    private let decorator: MarketListNftCollectionDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>>(value: .loading)

    init(service: MarketNftTopCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketListServiceState<NftCollectionItem>) {
        let listCount = listCount

        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case let .failed(error):
            stateRelay.accept(.failed(error))
        case let .loaded(items, _, _):
            stateRelay.accept(.completed(viewItem(listItems: Array(items.prefix(listCount)))))
        }
    }

    private func viewItem(listItems: [NftCollectionItem]) -> BaseMarketOverviewTopListDataSource.ViewItem {
        BaseMarketOverviewTopListDataSource.ViewItem(
                rightSelectorMode: .selector,
                imageName: "image_2_20",
                title: "market.top.top_collections".localized,
                listViewItems: listItems.map {
                    decorator.listViewItem(item: $0)
                }
        )
    }

}

extension MarketOverviewNftCollectionsViewModel: IMarketOverviewSectionViewModel {

    var stateObservable: Observable<DataStatus<()>> {
        stateRelay.map { $0.map { _ in () } }
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewNftCollectionsViewModel: IBaseMarketOverviewTopListViewModel {

    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem? {
        stateRelay.value.data
    }

    var selectorTitles: [String] {
        MarketNftTopCollectionsModule.selectorValues.map { $0.title }
    }

    var selectorIndex: Int {
        MarketNftTopCollectionsModule.selectorValues.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        service.timePeriod = MarketNftTopCollectionsModule.selectorValues[selectorIndex]
    }

}
