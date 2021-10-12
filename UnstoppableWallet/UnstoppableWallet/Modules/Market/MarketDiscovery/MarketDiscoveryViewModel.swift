import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class MarketDiscoveryViewModel {
    private let service: MarketDiscoveryService
    private let disposeBag = DisposeBag()

    private let discoveryViewItemsRelay = BehaviorRelay<[DiscoveryViewItem]?>(value: nil)
    private let searchViewItemsRelay = BehaviorRelay<[SearchViewItem]?>(value: nil)

    init(service: MarketDiscoveryService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketDiscoveryService.State) {
        switch state {
        case .discovery(let items):
            discoveryViewItemsRelay.accept(items.map { discoveryViewItem(item: $0) })
            searchViewItemsRelay.accept(nil)
        case .searchResults(let fullCoins):
            searchViewItemsRelay.accept(fullCoins.map { searchViewItem(fullCoin: $0) })
            discoveryViewItemsRelay.accept(nil)
        }
    }

    private func discoveryViewItem(item: MarketDiscoveryService.DiscoveryItem) -> DiscoveryViewItem {
        switch item {
        case .topCoins:
            return DiscoveryViewItem(
                    type: .topCoins,
                    imageType: .local(name: "Categories - Top Coins"),
                    name: "market_discovery.top_coins".localized
            )
        case .category(let category):
            return DiscoveryViewItem(
                    type: .category(uid: category.uid),
                    imageType: .remote(url: category.imageUrl),
                    name: category.name
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

    var searchViewItemsDriver: Driver<[SearchViewItem]?> {
        searchViewItemsRelay.asDriver()
    }

    func onUpdate(filter: String) {
        service.set(filter: filter)
    }

    func isFavorite(index: Int) -> Bool {
        service.isFavorite(index: index)
    }

    func favorite(index: Int) {
        service.favorite(index: index)
    }

    func unfavorite(index: Int) {
        service.unfavorite(index: index)
    }

}

extension MarketDiscoveryViewModel {

    struct DiscoveryViewItem {
        let type: Type
        let imageType: ImageType
        let name: String

        enum `Type` {
            case topCoins
            case category(uid: String)
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
