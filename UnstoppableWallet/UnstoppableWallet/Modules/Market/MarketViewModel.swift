import RxSwift
import RxRelay
import RxCocoa

class MarketViewModel {
    private let service: MarketService
    private let disposeBag = DisposeBag()

    private let currentTabRelay: BehaviorRelay<MarketModule.Tab>
    private let discoveryListTypeRelay = BehaviorRelay<MarketModule.ListType?>(value: nil)

    init(service: MarketService) {
        self.service = service

        currentTabRelay = BehaviorRelay<MarketModule.Tab>(value: service.currentTab ?? .overview)
    }

}

extension MarketViewModel {

    var currentTabDriver: Driver<MarketModule.Tab> {
        currentTabRelay.asDriver()
    }

    var discoveryListTypeDriver: Driver<MarketModule.ListType?> {
        discoveryListTypeRelay.asDriver()
    }

    var tabs: [MarketModule.Tab] {
        MarketModule.Tab.allCases
    }

    func onSelect(tab: MarketModule.Tab) {
        service.currentTab = tab
        currentTabRelay.accept(tab)
    }

    func handleTapSeeAll(listType: MarketModule.ListType) {
        discoveryListTypeRelay.accept(listType)
        onSelect(tab: .discovery)
    }

}
