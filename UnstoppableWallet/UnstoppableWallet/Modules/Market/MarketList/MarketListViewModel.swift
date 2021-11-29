import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

protocol IMarketListService {
    associatedtype Item

    var state: MarketListServiceState<Item> { get }
    var stateObservable: Observable<MarketListServiceState<Item>> { get }
    func refresh()
}

protocol IMarketListCoinUidService {
    func coinUid(index: Int) -> String?
}

protocol IMarketListDecoratorService {
    var initialMarketField: MarketModule.MarketField { get }
    var currency: Currency { get }
    var priceChangeType: MarketModule.PriceChangeType { get }
    func onUpdate(marketField: MarketModule.MarketField)
}

protocol IMarketListDecorator {
    associatedtype Item

    func listViewItem(item: Item) -> MarketModule.ListViewItem
}

enum MarketListServiceState<T> {
    case loading
    case loaded(items: [T], softUpdate: Bool, reorder: Bool)
    case failed(error: Error)
}

class MarketListViewModel<Service: IMarketListService, Decorator: IMarketListDecorator> {
    private let service: Service
    private let watchlistToggleService: MarketWatchlistToggleService
    private let decorator: Decorator
    private let disposeBag = DisposeBag()

    private let viewItemDataRelay = BehaviorRelay<MarketModule.ListViewItemData?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let scrollToTopRelay = PublishRelay<()>()

    init(service: Service, watchlistToggleService: MarketWatchlistToggleService, decorator: Decorator) {
        self.service = service
        self.watchlistToggleService = watchlistToggleService
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketListServiceState<Service.Item>) {
        switch state {
        case .loading:
            viewItemDataRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .loaded(let items, let softUpdate, let reorder):
            let data = MarketModule.ListViewItemData(viewItems: viewItems(items: items), softUpdate: softUpdate)
            viewItemDataRelay.accept(data)
            loadingRelay.accept(false)
            errorRelay.accept(nil)

            if reorder {
                scrollToTopRelay.accept(())
            }
        case .failed:
            viewItemDataRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func viewItems(items: [Service.Item]) -> [MarketModule.ListViewItem] {
        items.compactMap { item in
            guard let item = item as? Decorator.Item else {
                return nil
            }

            return decorator.listViewItem(item: item)
        }
    }

}

extension MarketListViewModel: IMarketListViewModel {

    var viewItemDataDriver: Driver<MarketModule.ListViewItemData?> {
        viewItemDataRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var scrollToTopSignal: Signal<()> {
        scrollToTopRelay.asSignal()
    }

    func isFavorite(index: Int) -> Bool? {
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
