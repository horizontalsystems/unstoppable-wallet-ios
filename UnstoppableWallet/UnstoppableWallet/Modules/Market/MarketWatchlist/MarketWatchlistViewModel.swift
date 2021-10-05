import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class MarketWatchlistViewModel {
    private let service: MarketWatchlistService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    private var sortingField: MarketModule.SortingField = .highestCap
    private var marketField: MarketModule.MarketField = .price

    init(service: MarketWatchlistService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketWatchlistService.State) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .loaded(let marketInfos):
            stateRelay.accept(.loaded(viewItems: viewItems(marketInfos: marketInfos)))
        case .failed:
            stateRelay.accept(.failed(description: "market.sync_error".localized))
        }
    }

    private func viewItems(marketInfos: [MarketInfo]) -> [MarketModule.ViewItemNew] {
        marketInfos.sorted(by: sortingField).map { viewItem(marketInfo: $0) }
    }

    private func viewItem(marketInfo: MarketInfo) -> MarketModule.ViewItemNew {
        MarketModule.ViewItemNew(marketInfo: marketInfo, marketField: marketField, currency: service.currency)
    }

    private func syncViewItemsIfPossible() {
        guard case .loaded(let marketInfos) = service.state else {
            return
        }

        stateRelay.accept(.loaded(viewItems: viewItems(marketInfos: marketInfos)))
    }

}

extension MarketWatchlistViewModel: IMarketMultiSortHeaderViewModel {

    var sortingFields: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }

    var marketFields: [String] {
        MarketModule.MarketField.allCases.map { $0.title }
    }

    var sortingFieldIndex: Int {
        MarketModule.SortingField.allCases.firstIndex(of: sortingField) ?? 0
    }

    var marketFieldIndex: Int {
        MarketModule.MarketField.allCases.firstIndex(of: marketField) ?? 0
    }

    func onSelectSortingField(index: Int) {
        sortingField = MarketModule.SortingField.allCases[index]
        syncViewItemsIfPossible()
    }

    func onSelectMarketField(index: Int) {
        marketField = MarketModule.MarketField.allCases[index]
        syncViewItemsIfPossible()
    }

}

extension MarketWatchlistViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketWatchlistViewModel {

    enum State {
        case loading
        case loaded(viewItems: [MarketModule.ViewItemNew])
        case failed(description: String)
    }

}
