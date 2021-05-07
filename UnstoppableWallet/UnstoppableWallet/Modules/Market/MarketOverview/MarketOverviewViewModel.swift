import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketOverviewViewModel {
    private let service: MarketOverviewService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: MarketOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketOverviewService.State) {
        switch state {
        case .loading:
            if service.items.isEmpty {
                stateRelay.accept(.loading)
            }
        case .loaded:
            stateRelay.accept(.loaded(sectionViewItems: sectionViewItems))
        case .failed:
            stateRelay.accept(.error(description: "market.sync_error".localized))
        }
    }

    private var sectionViewItems: [SectionViewItem] {
        [
            sectionViewItem(by: .topGainers),
            sectionViewItem(by: .topLosers),
        ]
    }

    private func sectionViewItem(by listType: MarketModule.ListType, count: Int = 5) -> SectionViewItem {
        let viewItems: [MarketModule.ViewItem] = Array(service.items
            .sort(by: listType.sortingField)
            .map {
                MarketModule.ViewItem(item: $0, marketField: listType.marketField, currency: service.currency)
            }
            .prefix(count)
        )

        return SectionViewItem(listType: listType, viewItems: viewItems)
    }

}

extension MarketOverviewViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewViewModel {

    struct SectionViewItem {
        let listType: MarketModule.ListType
        let viewItems: [MarketModule.ViewItem]
    }

    enum State {
        case loading
        case loaded(sectionViewItems: [SectionViewItem])
        case error(description: String)
    }

}
