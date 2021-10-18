import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

protocol IMarketListService {
    var state: MarketListServiceState { get }
    var stateObservable: Observable<MarketListServiceState> { get }
    func refresh()
}

protocol IMarketListDecoratorService {
    var currency: Currency { get }
    var priceChangeType: MarketModule.PriceChangeType { get }
    func resyncIfPossible()
}

protocol IMarketListDecorator {
    func listViewItem(marketInfo: MarketInfo) -> MarketModule.ListViewItem
}

enum MarketListServiceState {
    case loading
    case loaded(marketInfos: [MarketInfo], softUpdate: Bool)
    case failed(error: Error)
}

class MarketListViewModel {
    private let service: IMarketListService
    private let watchlistToggleService: MarketWatchlistToggleService
    private let decorator: IMarketListDecorator
    private let disposeBag = DisposeBag()

    private let viewItemDataRelay = BehaviorRelay<ViewItemData?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: IMarketListService, watchlistToggleService: MarketWatchlistToggleService, decorator: IMarketListDecorator) {
        self.service = service
        self.watchlistToggleService = watchlistToggleService
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketListServiceState) {
        switch state {
        case .loading:
            viewItemDataRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .loaded(let marketInfos, let softUpdate):
            let data = ViewItemData(viewItems: viewItems(marketInfos: marketInfos), softUpdate: softUpdate)
            viewItemDataRelay.accept(data)
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemDataRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func syncViewItemsIfPossible() {
        guard case .loaded(let marketInfos, _) = service.state else {
            return
        }

        viewItemDataRelay.accept(ViewItemData(viewItems: viewItems(marketInfos: marketInfos), softUpdate: false))
    }

    private func viewItems(marketInfos: [MarketInfo]) -> [MarketModule.ListViewItem] {
        marketInfos.map {
            decorator.listViewItem(marketInfo: $0)
        }
    }

}

extension MarketListViewModel {

    var viewItemDataDriver: Driver<ViewItemData?> {
        viewItemDataRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func isFavorite(index: Int) -> Bool {
        watchlistToggleService.isFavorite(index: index)
    }

    func favorite(index: Int) {
        watchlistToggleService.favorite(index: index)
    }

    func unfavorite(index: Int) {
        watchlistToggleService.unfavorite(index: index)
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketListViewModel {

    struct ViewItemData {
        let viewItems: [MarketModule.ListViewItem]
        let softUpdate: Bool
    }

}
