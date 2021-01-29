import RxSwift
import RxRelay
import RxCocoa

class MarketViewModel {
    private let service: MarketService
    private let disposeBag = DisposeBag()

    private let currentTabRelay: BehaviorRelay<MarketModule.Tab>
    private let discoveryPreferenceRelay = PublishRelay<MarketModule.Preference>()

    init(service: MarketService) {
        self.service = service

        currentTabRelay = BehaviorRelay<MarketModule.Tab>(value: service.currentTab ?? .overview)
    }

}

extension MarketViewModel {

    var currentTabDriver: Driver<MarketModule.Tab> {
        currentTabRelay.asDriver()
    }

    var discoveryPreferenceSignal: Signal<MarketModule.Preference> {
        discoveryPreferenceRelay.asSignal()
    }

    var tabs: [MarketModule.Tab] {
        MarketModule.Tab.allCases
    }

    func onSelect(tab: MarketModule.Tab) {
        service.currentTab = tab
        currentTabRelay.accept(tab)
    }

    func handleTapSeeAll(sectionType: MarketModule.SectionType) {
        discoveryPreferenceRelay.accept(sectionType.preference)
        onSelect(tab: .discovery)
    }

}
