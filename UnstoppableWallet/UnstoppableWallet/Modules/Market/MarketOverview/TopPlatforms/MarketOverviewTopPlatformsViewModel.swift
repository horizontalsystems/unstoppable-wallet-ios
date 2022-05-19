import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewTopPlatformsViewModel {
    private let listCount = 5

    private let service: MarketTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>>(value: .loading)

    init(service: MarketTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketListServiceState<TopPlatform>) {
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

    private func viewItem(listItems: [TopPlatform]) -> BaseMarketOverviewTopListDataSource.ViewItem {
        BaseMarketOverviewTopListDataSource.ViewItem(
                rightSelectorMode: .selector,
                imageName: "blocks_20",
                title: "market.top.top_platforms".localized,
                listViewItems: listItems.map {
                    decorator.listViewItem(item: $0)
                }
        )
    }

}

extension MarketOverviewTopPlatformsViewModel: IMarketOverviewSectionViewModel {

    var stateObservable: Observable<DataStatus<()>> {
        stateRelay.map { $0.map { _ in () } }
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewTopPlatformsViewModel: IBaseMarketOverviewTopListViewModel {

    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem? {
        stateRelay.value.data
    }

    var selectorTitles: [String] {
        MarketTopPlatformsModule.selectorValues.map { $0.title }
    }

    var selectorIndex: Int {
        MarketTopPlatformsModule.selectorValues.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        service.timePeriod = MarketTopPlatformsModule.selectorValues[selectorIndex]
    }

}
