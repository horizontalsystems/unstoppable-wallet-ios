import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

protocol IMarketListService {
    var currency: Currency { get }
    var state: MarketListServiceState { get }
    var stateObservable: Observable<MarketListServiceState> { get }
    func refresh()
}

enum MarketListServiceState {
    case loading
    case loaded(marketInfos: [MarketInfo])
    case failed(error: Error)
}

class MarketListViewModel {
    private let service: IMarketListService
    private let disposeBag = DisposeBag()

    var marketField: MarketModule.MarketField {
        didSet {
            syncViewItemsIfPossible()
        }
    }

    private let viewItemsRelay = BehaviorRelay<[MarketModule.ListViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: IMarketListService, marketField: MarketModule.MarketField) {
        self.service = service
        self.marketField = marketField

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketListServiceState) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .loaded(let marketInfos):
            viewItemsRelay.accept(viewItems(marketInfos: marketInfos))
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func syncViewItemsIfPossible() {
        guard case .loaded(let marketInfos) = service.state else {
            return
        }

        viewItemsRelay.accept(viewItems(marketInfos: marketInfos))
    }

    private func viewItems(marketInfos: [MarketInfo]) -> [MarketModule.ListViewItem] {
        marketInfos.map {
            MarketModule.ListViewItem(marketInfo: $0, marketField: marketField, currency: service.currency)
        }
    }

}

extension MarketListViewModel {

    var viewItemsDriver: Driver<[MarketModule.ListViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}
