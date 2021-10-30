import RxSwift
import RxRelay
import MarketKit

class MarketDiscoveryService {
    private let marketKit: Kit
    private let favoritesManager: FavoritesManager

    private var discoveryItems = [DiscoveryItem]()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .discovery(items: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: Kit, favoritesManager: FavoritesManager) {
        self.marketKit = marketKit
        self.favoritesManager = favoritesManager

        syncDiscoveryItems()
        state = .discovery(items: discoveryItems)
    }

    private func syncDiscoveryItems() {
        var discoveryItems: [DiscoveryItem] = [.topCoins]

        do {
            for category in try marketKit.coinCategories() {
                discoveryItems.append(.category(category: category))
            }
        } catch {
            // do nothing
        }

        self.discoveryItems = discoveryItems
    }

    private func coinUid(index: Int) -> String? {
        guard case .searchResults(let fullCoins) = state, index < fullCoins.count else {
            return nil
        }

        return fullCoins[index].coin.uid
    }

}

extension MarketDiscoveryService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(filter: String) {
        if filter.isEmpty {
            state = .discovery(items: discoveryItems)
        } else {
            do {
                state = .searchResults(fullCoins: try marketKit.fullCoins(filter: filter))
            } catch {
                state = .searchResults(fullCoins: [])
            }
        }
    }

    func isFavorite(index: Int) -> Bool {
        guard let coinUid = coinUid(index: index) else {
            return false
        }

        return favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            return
        }

        favoritesManager.add(coinUid: coinUid)
    }

    func unfavorite(index: Int) {
        guard let coinUid = coinUid(index: index) else {
            return
        }

        favoritesManager.remove(coinUid: coinUid)
    }

}

extension MarketDiscoveryService {

    enum State {
        case discovery(items: [DiscoveryItem])
        case searchResults(fullCoins: [FullCoin])
    }

    enum DiscoveryItem {
        case topCoins
        case category(category: CoinCategory)
    }

}
