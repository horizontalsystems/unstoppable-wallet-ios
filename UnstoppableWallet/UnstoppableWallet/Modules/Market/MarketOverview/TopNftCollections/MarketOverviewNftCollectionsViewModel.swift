import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class MarketOverviewNftCollectionsViewModel {
    private let service: MarketOverviewNftCollectionsService
    private let decorator: MarketListNftCollectionDecorator
    private let disposeBag = DisposeBag()

    private let statusRelay = BehaviorRelay<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>>(value: .loading)

    init(service: MarketOverviewNftCollectionsService, decorator: MarketListNftCollectionDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(status: $0)
        }
    }

    private func sync(status: DataStatus<[NftCollectionItem]>) {
        statusRelay.accept(status.map({ listItems in
            viewItems(listItems: listItems)
        }))
    }

    private func viewItems(listItems: [NftCollectionItem]) -> [MarketOverviewTopCoinsViewModel.TopViewItem] {
        [
            MarketOverviewTopCoinsViewModel.TopViewItem(
                    listType: .topCollections,
                    imageName: "image_2_20",
                    title: "market.top.top_collections".localized,
                    listViewItems: listItems.map {
                        decorator.listViewItem(item: $0)
                    }
            )
        ]
    }

}

extension MarketOverviewNftCollectionsViewModel: IMarketOverviewTopCoinsViewModel {

    var statusDriver: Driver<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>> {
        statusRelay.asDriver()
    }
    var marketTops: [String] {
        []
    }

    func marketTop(listType: MarketOverviewTopCoinsService.ListType) -> MarketModule.MarketTop {
        .top250
    }

    func marketTopIndex(listType: MarketOverviewTopCoinsService.ListType) -> Int {
        0
    }

    func onSelect(marketTopIndex: Int, listType: MarketOverviewTopCoinsService.ListType) {
    }

    func refresh() {
        service.refresh()
    }

}
