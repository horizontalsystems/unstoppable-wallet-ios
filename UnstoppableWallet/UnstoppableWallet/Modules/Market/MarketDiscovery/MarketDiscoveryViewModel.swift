import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketDiscoveryViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketDiscoveryService

    private let viewItemsRelay = BehaviorRelay<[MarketModule.ViewItem]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private var sortingField: MarketModule.SortingField
    private(set) var marketField: MarketModule.MarketField = .marketCap

    init(service: MarketDiscoveryService) {
        self.service = service

        sortingField = .highestCap
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketDiscoveryService.State) {
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

    private func syncViewItems() {
        let viewItems: [MarketModule.ViewItem] = service.items.sort(by: sortingField).map {
            MarketModule.ViewItem(item: $0, marketField: marketField, currency: service.currency)
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension MarketDiscoveryViewModel {

    var sortingFieldTitle: String {
        sortingField.title
    }

    var viewItemsDriver: Driver<[MarketModule.ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var sortingFields: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }

    func refresh() {
        service.refresh()
    }

    func setSortingField(at index: Int) {
        sortingField = MarketModule.SortingField.allCases[index]

        syncViewItems()
    }

    func set(marketField: MarketModule.MarketField) {
        self.marketField = marketField

        syncViewItems()
    }

    func setFilter(at index: Int?) {
        guard let index = index, index < MarketDiscoveryFilter.allCases.count else {
            service.currentCategory = nil
            return
        }

        service.currentCategory = MarketDiscoveryFilter.allCases[index]
    }

    func set(listType: MarketModule.ListType) {
        sortingField = listType.sortingField
        marketField = listType.marketField

        syncViewItems()
    }

}
