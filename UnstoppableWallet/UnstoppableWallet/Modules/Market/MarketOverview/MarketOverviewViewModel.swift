import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketOverviewViewModel {
    private let disposeBag = DisposeBag()

    private let service: MarketOverviewService

    private let viewItemsRelay = BehaviorRelay<[Section]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: MarketOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketOverviewService.State) {
        if case .loaded = state {
            syncViewItems()
        }

        if case .loading = state {
            isLoadingRelay.accept(true)
        } else {
            isLoadingRelay.accept(false)
        }

        if case let .error(error: error) = state {
            errorRelay.accept(error.smartDescription)
        } else {
            errorRelay.accept(nil)
        }
    }

    private func sectionItems(by listType: MarketModule.ListType, count: Int = 3) -> Section {
        let viewItems: [MarketModule.ViewItem] = Array(service.items
            .sort(by: listType.sortingField)
            .map {
                MarketModule.ViewItem(item: $0, marketField: listType.marketField, currency: service.currency)
            }
            .prefix(count)
        )

        return Section(listType: listType, viewItems: viewItems)
    }

    private func syncViewItems() {
        let sections = [
            sectionItems(by: .topGainers),
            sectionItems(by: .topLosers),
            sectionItems(by: .topVolume)
        ]

        viewItemsRelay.accept(sections)
    }

}

extension MarketOverviewViewModel {

    var viewItemsDriver: Driver<[Section]> {
        viewItemsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewViewModel {

    struct Section {
        let listType: MarketModule.ListType
        let viewItems: [MarketModule.ViewItem]
    }

}
