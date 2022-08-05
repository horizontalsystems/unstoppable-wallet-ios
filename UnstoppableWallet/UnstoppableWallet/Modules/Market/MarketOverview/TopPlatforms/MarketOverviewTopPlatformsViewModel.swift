import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class MarketOverviewTopPlatformsViewModel {
    private let service: MarketOverviewTopPlatformsService
    private let decorator: MarketListTopPlatformDecorator
    private let disposeBag = DisposeBag()

    private let listViewItemsRelay = BehaviorRelay<[MarketModule.ListViewItem]?>(value: nil)

    init(service: MarketOverviewTopPlatformsService, decorator: MarketListTopPlatformDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.topPlatformsObservable) { [weak self] in self?.sync(topPlatforms: $0) }

        sync(topPlatforms: service.topPlatforms)
    }

    private func sync(topPlatforms: [TopPlatform]?) {
        listViewItemsRelay.accept(topPlatforms.map { $0.map { decorator.listViewItem(item: $0) } })
    }

}

extension MarketOverviewTopPlatformsViewModel {

    var timePeriod: HsTimePeriod {
        service.timePeriod
    }

    func topPlatform(uid: String) -> TopPlatform? {
        service.topPlatforms?.first { $0.blockchain.uid == uid }
    }

}

extension MarketOverviewTopPlatformsViewModel: IBaseMarketOverviewTopListViewModel {

    var listViewItemsDriver: Driver<[MarketModule.ListViewItem]?> {
        listViewItemsRelay.asDriver()
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
