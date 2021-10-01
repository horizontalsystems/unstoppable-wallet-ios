import RxSwift
import RxRelay
import MarketKit

class MarketDiscoveryService {
    private let marketKit: Kit

    private var discoveryItems = [DiscoveryItem]()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .discovery(items: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: Kit) {
        self.marketKit = marketKit

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
