import Foundation
import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class MarketDiscoveryViewModel {
    private var queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.market-discovery-view-model", qos: .userInitiated)

    private let categoryService: MarketDiscoveryCategoryService
    private let filterService: MarketDiscoveryFilterService
    private let disposeBag = DisposeBag()

    private let discoveryViewItemsRelay = BehaviorRelay<[DiscoveryViewItem]?>(value: nil)
    private let discoveryLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let discoveryErrorRelay = BehaviorRelay<String?>(value: nil)
    private let searchViewItemsRelay = BehaviorRelay<[SearchViewItem]?>(value: nil)
    private let favoritedRelay = PublishRelay<()>()
    private let unfavoritedRelay = PublishRelay<()>()
    private let failRelay = PublishRelay<()>()

    init(categoryService: MarketDiscoveryCategoryService, filterService: MarketDiscoveryFilterService) {
        self.categoryService = categoryService
        self.filterService = filterService

        subscribe(disposeBag, categoryService.stateObservable) { [weak self] in self?.sync(categoryState: $0) }
        subscribe(disposeBag, filterService.stateObservable) { [weak self] in self?.sync(filterState: $0) }
        subscribe(disposeBag, filterService.resultObservable) { [weak self] in self?.sync(result: $0) }

        serialSync()
    }

    private func sync(categoryState: MarketDiscoveryCategoryService.State? = nil, filterState: MarketDiscoveryFilterService.State? = nil) {
        queue.async { [weak self] in
            self?.serialSync(categoryState: categoryState, filterState: filterState)
        }
    }

    private func sync(result: MarketDiscoveryFilterService.Result) {
        switch result {
        case .favorited: favoritedRelay.accept(())
        case .unfavorited: unfavoritedRelay.accept(())
        case .fail: failRelay.accept(())
        }
    }

    private func serialSync(categoryState: MarketDiscoveryCategoryService.State? = nil, filterState: MarketDiscoveryFilterService.State? = nil) {
        let categoryState = categoryState ?? categoryService.state
        let filterState = filterState ?? filterService.state

        switch filterState {
        case .idle:
            searchViewItemsRelay.accept(nil)
        case .searchResults(let fullCoins):
            searchViewItemsRelay.accept(fullCoins.map { searchViewItem(fullCoin: $0) })
            discoveryLoadingRelay.accept(false)
            discoveryErrorRelay.accept(nil)
            discoveryViewItemsRelay.accept(nil)
            return
        }

        switch categoryState {
        case .loading:
            discoveryErrorRelay.accept(nil)
            discoveryLoadingRelay.accept(true)
            discoveryViewItemsRelay.accept(nil)
        case .items(let items):
            discoveryErrorRelay.accept(nil)
            discoveryLoadingRelay.accept(false)
            discoveryViewItemsRelay.accept(items.map { discoveryViewItem(item: $0) })
        case .failed(let error):
            discoveryErrorRelay.accept(error.localizedDescription)
            discoveryLoadingRelay.accept(false)
            discoveryViewItemsRelay.accept(nil)
        }
    }

    private func discoveryViewItem(item: MarketDiscoveryCategoryService.DiscoveryItem) -> DiscoveryViewItem {
        switch item {
        case .topCoins:
            return DiscoveryViewItem(
                    type: .topCoins,
                    imageType: .local(name: "Categories - Top Coins"),
                    name: "market_discovery.top_coins".localized,
                    marketCap: nil,
                    diff: nil,
                    diffType: .up
            )
        case .category(let category):
            let (marketCap, diffString, diffType) = MarketDiscoveryModule.formatCategoryMarketData(category: category, timePeriod: categoryService.timePeriod, currency: categoryService.currency)

            return DiscoveryViewItem(
                    type: .category(category: category),
                    imageType: .remote(url: category.imageUrl),
                    name: category.name,
                    marketCap: marketCap,
                    diff: diffString,
                    diffType: diffType
            )
        }
    }

    private func searchViewItem(fullCoin: FullCoin) -> SearchViewItem {
        SearchViewItem(
                uid: fullCoin.coin.uid,
                imageUrl: fullCoin.coin.imageUrl,
                placeholderImageName: fullCoin.placeholderImageName,
                name: fullCoin.coin.name,
                code: fullCoin.coin.code,
                favorite: false
        )
    }

}

extension MarketDiscoveryViewModel {

    var discoveryViewItemsDriver: Driver<[DiscoveryViewItem]?> {
        discoveryViewItemsRelay.asDriver()
    }

    var discoveryLoadingDriver: Driver<Bool> {
        discoveryLoadingRelay.asDriver()
    }

    var discoveryErrorDriver: Driver<String?> {
        discoveryErrorRelay.asDriver()
    }

    var searchViewItemsDriver: Driver<[SearchViewItem]?> {
        searchViewItemsRelay.asDriver()
    }

    var favoritedDriver: Driver<()> {
        favoritedRelay.asDriver(onErrorJustReturn: ())
    }

    var unfavoritedDriver: Driver<()> {
        unfavoritedRelay.asDriver(onErrorJustReturn: ())
    }

    var failDriver: Driver<()> {
        failRelay.asDriver(onErrorJustReturn: ())
    }

    func refresh() {
        categoryService.refresh()
    }

    func onUpdate(filter: String) {
        filterService.set(filter: filter)
    }

    func isFavorite(index: Int) -> Bool {
        filterService.isFavorite(index: index)
    }

    func favorite(index: Int) {
        filterService.favorite(index: index)
    }

    func unfavorite(index: Int) {
        filterService.unfavorite(index: index)
    }

}

extension MarketDiscoveryViewModel {

    struct DiscoveryViewItem {
        let type: Type
        let imageType: ImageType
        let name: String
        let marketCap: String?
        let diff: String?
        let diffType: MarketDiscoveryModule.DiffType

        enum `Type` {
            case topCoins
            case category(category: CoinCategory)
        }

        enum ImageType {
            case local(name: String)
            case remote(url: String)
        }

    }

    struct SearchViewItem {
        let uid: String
        let imageUrl: String
        let placeholderImageName: String
        let name: String
        let code: String
        let favorite: Bool
    }

}
