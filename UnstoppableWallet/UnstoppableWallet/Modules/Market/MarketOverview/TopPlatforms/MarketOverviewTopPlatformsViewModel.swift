import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewTopPlatformsViewModel {
    private let service: MarketOverviewTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator
    private let disposeBag = DisposeBag()

    private let statusRelay = BehaviorRelay<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>>(value: .loading)

    init(service: MarketOverviewTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<[MarketKit.TopPlatform]>) {
        statusRelay.accept(status.map({ listItems in
            viewItems(listItems: listItems)
        }))
    }

    private func viewItems(listItems: [MarketKit.TopPlatform]) -> [MarketOverviewTopCoinsViewModel.TopViewItem] {
        [
            MarketOverviewTopCoinsViewModel.TopViewItem(
                    listType: .topPlatforms,
                    imageName: "blocks_20",
                    title: "market.top.top_platforms".localized,
                    listViewItems: listItems.map {
                        decorator.listViewItem(item: $0)
                    }
            )
        ]
    }

}

extension MarketOverviewTopPlatformsViewModel: IMarketOverviewTopCoinsViewModel {

    var statusDriver: Driver<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>> {
        statusRelay.asDriver()
    }

    var marketTops: [String] {
        MarketOverviewTopPlatformsService.TimePeriod.allCases.map { $0.title }
    }

    func marketTop(listType: MarketOverviewTopCoinsService.ListType) -> MarketModule.MarketTop {
        .top250
    }

    func marketTopIndex(listType: MarketOverviewTopCoinsService.ListType) -> Int {
        MarketOverviewTopPlatformsService.TimePeriod.allCases.index(of: service.timePeriod) ?? 0
    }

    func onSelect(marketTopIndex: Int, listType: MarketOverviewTopCoinsService.ListType) {
        let timePeriod = MarketOverviewTopPlatformsService.TimePeriod.allCases[marketTopIndex]
        decorator.timePeriod = timePeriod
        service.timePeriod = timePeriod
    }

    func refresh() {
        service.refresh()
    }

    func collection(uid: String) -> NftCollection? {
        nil
    }

}
