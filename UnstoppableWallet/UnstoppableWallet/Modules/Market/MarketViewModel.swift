import RxSwift
import RxRelay
import RxCocoa

class MarketViewModel {
    private let service: MarketService
    private let disposeBag = DisposeBag()

    private let currentTabRelay: BehaviorRelay<MarketModule.Tab>
    private let discoveryListTypeRelay = PublishRelay<MarketModule.ListType>()

    init(service: MarketService) {
        self.service = service

        currentTabRelay = BehaviorRelay<MarketModule.Tab>(value: service.currentTab ?? .overview)
    }

}

extension MarketViewModel {

    var currentTabDriver: Driver<MarketModule.Tab> {
        currentTabRelay.asDriver()
    }

    var discoveryListTypeSignal: Signal<MarketModule.ListType> {
        discoveryListTypeRelay.asSignal()
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
