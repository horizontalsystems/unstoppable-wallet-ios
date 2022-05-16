import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewTopPlatformsViewModel {
    private let service: MarketOverviewTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<()>>(value: .loading)

    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem?

    init(service: MarketOverviewTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<[MarketKit.TopPlatform]>) {
        stateRelay.accept(status.map({ [weak self] listItems in
            self?.createViewItem(listItems: listItems)

            return ()
        }))
    }

    private func createViewItem(listItems: [MarketKit.TopPlatform]) {
        viewItem = .init(
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

    var stateDriver: Driver<DataStatus<()>> {
        stateRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewTopPlatformsViewModel: IBaseMarketOverviewTopListViewModel {

    var selectorValues: [String] {
        [
            HsTimePeriod.day1,
            HsTimePeriod.week1,
            HsTimePeriod.month1
        ].map {
            $0.title
        }
    }

    var selectorIndex: Int {
        HsTimePeriod.allCases.firstIndex(of: service.timePeriod) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        let timePeriod = HsTimePeriod.allCases[selectorIndex]
        decorator.timePeriod = timePeriod
        service.timePeriod = timePeriod
    }

}
