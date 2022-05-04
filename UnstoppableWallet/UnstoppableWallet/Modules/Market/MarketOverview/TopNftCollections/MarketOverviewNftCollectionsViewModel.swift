import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class MarketOverviewNftCollectionsViewModel {
    private let service: MarketOverviewNftCollectionsService
    private let decorator: MarketListNftCollectionDecorator
    private let disposeBag = DisposeBag()

    private let statusRelay = BehaviorRelay<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>>(value: .loading)

    init(service: MarketOverviewNftCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(status: $0)
        }
    }

    private func sync(status: DataStatus<[NftCollectionItem]>) {
        statusRelay.accept(status.map({ listItems in
            viewItem(listItems: listItems)
        }))
    }

    private func viewItem(listItems: [NftCollectionItem]) -> BaseMarketOverviewTopListDataSource.ViewItem {
        BaseMarketOverviewTopListDataSource.ViewItem(
                rightSelectorMode: .none,
                imageName: "image_2_20",
                title: "market.top.top_collections".localized,
                listViewItems: listItems.map {
                    decorator.listViewItem(item: $0)
                }
        )
    }

}

extension MarketOverviewNftCollectionsViewModel: IBaseMarketOverviewTopListViewModel {

    var statusDriver: Driver<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>> {
        statusRelay.asDriver()
    }

    var selectorValues: [String] {
        []
    }

    var selectorIndex: Int {
        0
    }

    func onSelect(selectorIndex: Int) {
    }

    func refresh() {
        service.refresh()
    }

}
