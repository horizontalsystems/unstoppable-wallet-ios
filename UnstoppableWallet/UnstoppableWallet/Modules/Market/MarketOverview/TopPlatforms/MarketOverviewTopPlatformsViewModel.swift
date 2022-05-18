import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewTopPlatformsViewModel {
    private let service: MarketOverviewTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>>(value: .loading)

    init(service: MarketOverviewTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: DataStatus<[TopPlatform]>) {
        stateRelay.accept(state.map { viewItem(listItems: $0) })
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
