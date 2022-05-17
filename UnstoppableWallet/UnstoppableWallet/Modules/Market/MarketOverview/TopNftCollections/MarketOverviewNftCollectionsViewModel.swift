import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewNftCollectionsViewModel {
    private let listCount = 5

    private let service: MarketNftTopCollectionsService
    private let decorator: MarketListNftCollectionDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<()>>(value: .loading)

    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem?

    init(service: MarketNftTopCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(status: $0)
        }
    }

    private func sync(status: MarketListServiceState<NftCollectionItem>) {
        let listCount = listCount

        switch status {
        case .loading:
            stateRelay.accept(.loading)
        case let .failed(error):
            stateRelay.accept(.failed(error))
        case let .loaded(items, _, _):
            createViewItem(listItems: Array(items.prefix(listCount)))

            stateRelay.accept(.completed(()))
        }
    }

    private func createViewItem(listItems: [NftCollectionItem]) {
        viewItem = .init(
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

    var stateDriver: Driver<DataStatus<()>> {
        stateRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewNftCollectionsViewModel: IBaseMarketOverviewTopListViewModel {

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
