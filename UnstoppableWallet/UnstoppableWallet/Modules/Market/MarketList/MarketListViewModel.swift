import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketListViewModel {
    private let service: MarketListService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    private let sortingFieldTitleRelay: BehaviorRelay<String>
    private let marketFieldRelay = BehaviorRelay<MarketModule.MarketField>(value: .price)

    private var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            sortingFieldTitleRelay.accept(sortingField.title)
        }
    }

    init(service: MarketListService) {
        self.service = service
        sortingFieldTitleRelay = BehaviorRelay(value: sortingField.title)

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketListService.State) {
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

extension MarketListViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    var sortingFieldTitleDriver: Driver<String> {
        sortingFieldTitleRelay.asDriver()
    }

    var marketFieldDriver: Driver<MarketModule.MarketField> {
        marketFieldRelay.asDriver()
    }

    var allMarketFields: [MarketModule.MarketField] {
        service.allMarketFields
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

    func set(listType: MarketModule.ListType) {
        sortingField = listType.sortingField
        marketFieldRelay.accept(listType.marketField)

        syncViewItemsIfPossible()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketListViewModel {

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
