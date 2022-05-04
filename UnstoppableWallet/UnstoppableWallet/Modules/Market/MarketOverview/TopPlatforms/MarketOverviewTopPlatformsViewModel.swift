import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewTopPlatformsViewModel {
    private let service: MarketOverviewTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator
    private let disposeBag = DisposeBag()

    private let statusRelay = BehaviorRelay<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>>(value: .loading)

    init(service: MarketOverviewTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<[MarketKit.TopPlatform]>) {
        statusRelay.accept(status.map({ listItems in
            viewItem(listItems: listItems)
        }))
    }

    private func viewItem(listItems: [MarketKit.TopPlatform]) -> BaseMarketOverviewTopListDataSource.ViewItem {
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

extension MarketOverviewTopPlatformsViewModel: IBaseMarketOverviewTopListViewModel {

    var statusDriver: Driver<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>> {
        statusRelay.asDriver()
    }

    var selectorValues: [String] {
        MarketOverviewTopPlatformsService.TimePeriod.allCases.map { $0.title }
    }

    var selectorIndex: Int {
        MarketOverviewTopPlatformsService.TimePeriod.allCases.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        let timePeriod = MarketOverviewTopPlatformsService.TimePeriod.allCases[selectorIndex]
        decorator.timePeriod = timePeriod
        service.timePeriod = timePeriod
    }

    func refresh() {
        service.refresh()
    }

}
