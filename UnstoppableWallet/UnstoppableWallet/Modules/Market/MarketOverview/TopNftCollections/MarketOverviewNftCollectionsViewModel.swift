import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class MarketOverviewNftCollectionsViewModel {
    private let service: MarketOverviewNftCollectionsService
    private let decorator: MarketListNftCollectionDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<()>>(value: .loading)

    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem?

    init(service: MarketOverviewNftCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(status: $0)
        }
    }

    private func sync(status: DataStatus<[NftCollectionItem]>) {
        stateRelay.accept(status.map({ [weak self] listItems in
            self?.createViewItem(listItems: listItems)

            return ()
        }))
    }

    private func createViewItem(listItems: [NftCollectionItem]) {
        viewItem = .init(
                rightSelectorMode: .none,
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

    var selectorValues: [String] {
        []
    }

    var selectorIndex: Int {
        0
    }

    func onSelect(selectorIndex: Int) {
    }

}
