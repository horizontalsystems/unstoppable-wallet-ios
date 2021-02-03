import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketDiscoveryViewModel {
    private let service: MarketDiscoveryService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    private let sortingFieldTitleRelay: BehaviorRelay<String>
    private let marketFieldRelay = BehaviorRelay<MarketModule.MarketField>(value: .marketCap)
    private let selectedFilterIndexRelay = BehaviorRelay<Int?>(value: nil)

    private var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            sortingFieldTitleRelay.accept(sortingField.title)
        }
    }

    init(service: MarketDiscoveryService) {
        self.service = service
        sortingFieldTitleRelay = BehaviorRelay(value: sortingField.title)

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.currentCategoryObservable) { [weak self] in self?.sync(currentCategory: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketDiscoveryService.State) {
        switch state {
        case .loading:
            if service.items.isEmpty {
                stateRelay.accept(.loading)
            }
        case .loaded:
            stateRelay.accept(.loaded(viewItems: viewItems))
        case .failed:
            stateRelay.accept(.error(description: "market.sync_error".localized))
        }
    }

    private func sync(currentCategory: MarketDiscoveryFilter?) {
        var index: Int?

        if let currentCategory = currentCategory {
            index = MarketDiscoveryFilter.allCases.firstIndex(of: currentCategory)
        }

        selectedFilterIndexRelay.accept(index)
    }

    private var viewItems: [MarketModule.ViewItem] {
        service.items.sort(by: sortingField).map {
            MarketModule.ViewItem(item: $0, marketField: marketFieldRelay.value, currency: service.currency)
        }
    }

    private func syncViewItemsIfPossible() {
        guard case .loaded = stateRelay.value  else {
            return
        }

        stateRelay.accept(.loaded(viewItems: viewItems))
    }

}

extension MarketDiscoveryViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    var sortingFieldTitleDriver: Driver<String> {
        sortingFieldTitleRelay.asDriver()
    }

    var marketFieldDriver: Driver<MarketModule.MarketField> {
        marketFieldRelay.asDriver()
    }

    var selectedFilterIndexDriver: Driver<Int?> {
        selectedFilterIndexRelay.asDriver()
    }

    var sortingFieldViewItems: [SortingFieldViewItem] {
        MarketModule.SortingField.allCases.map {
            SortingFieldViewItem(
                    title: $0.title,
                    selected: sortingField == $0
            )
        }
    }

    func setSortingField(at index: Int) {
        sortingField = MarketModule.SortingField.allCases[index]

        syncViewItemsIfPossible()
    }

    func set(marketField: MarketModule.MarketField) {
        marketFieldRelay.accept(marketField)

        syncViewItemsIfPossible()
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
        marketFieldRelay.accept(listType.marketField)

        if service.currentCategory != nil {
            service.currentCategory = nil
        }

        syncViewItemsIfPossible()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketDiscoveryViewModel {

    struct SortingFieldViewItem {
        let title: String
        let selected: Bool
    }

    enum State {
        case loading
        case loaded(viewItems: [MarketModule.ViewItem])
        case error(description: String)
    }

}
