import Combine
import MarketKit

class MarketViewModel {
    private let keyTabIndex = "market-tab-index"
    private let keyRecentCoinUids = "market-recent-coin-uids"

    private let userDefaultsStorage = App.shared.userDefaultsStorage
    private let launchScreenManager = App.shared.launchScreenManager
    private let marketKit = App.shared.marketKit
    private let favoritesManager = App.shared.favoritesManager

    @Published var currentTab: MarketModule.Tab {
        didSet {
            userDefaultsStorage.set(value: currentTab.rawValue, for: keyTabIndex)
        }
    }

    @Published private(set) var state: State = .idle

    private var recentCoinUids: [String] {
        didSet {
            userDefaultsStorage.set(value: recentCoinUids.joined(separator: ","), for: keyRecentCoinUids)
        }
    }

    private let favoritedSubject = PassthroughSubject<Void, Never>()
    private let unfavoritedSubject = PassthroughSubject<Void, Never>()

    init() {
        let currentTab: MarketModule.Tab

        switch launchScreenManager.launchScreen {
        case .auto:
            if let storedIndex: Int = userDefaultsStorage.value(for: keyTabIndex), let storedTab = MarketModule.Tab(rawValue: storedIndex) {
                currentTab = storedTab
            } else {
                currentTab = .overview
            }
        case .balance, .marketOverview:
            currentTab = .overview
        case .watchlist:
            currentTab = .watchlist
        }

        self.currentTab = currentTab

        let recentCoinsUidsRaw: String = userDefaultsStorage.value(for: keyRecentCoinUids) ?? ""
        recentCoinUids = recentCoinsUidsRaw.components(separatedBy: ",")
    }
}

extension MarketViewModel {
    var favoritedPublisher: AnyPublisher<Void, Never> {
        favoritedSubject.eraseToAnyPublisher()
    }

    var unfavoritedPublisher: AnyPublisher<Void, Never> {
        unfavoritedSubject.eraseToAnyPublisher()
    }

    func onUpdate(searchActive: Bool, filter: String) {
        if searchActive {
            if filter.isEmpty {
                let recentMarketFullCoins = (try? marketKit.fullCoins(coinUids: recentCoinUids)) ?? []
                let recentFullCoins = recentCoinUids.compactMap { coinUid in recentMarketFullCoins.first { $0.coin.uid == coinUid } }

                let popularFullCoins = (try? marketKit.topFullCoins()) ?? []

                state = .placeholder(recentFullCoins: recentFullCoins, popularFullCoins: popularFullCoins)
            } else {
                state = .searchResults(fullCoins: (try? marketKit.fullCoins(filter: filter)) ?? [])
            }
        } else {
            state = .idle
        }
    }

    func isFavorite(coinUid: String) -> Bool {
        favoritesManager.isFavorite(coinUid: coinUid)
    }

    func favorite(coinUid: String) {
        favoritesManager.add(coinUid: coinUid)
        favoritedSubject.send()
    }

    func unfavorite(coinUid: String) {
        favoritesManager.remove(coinUid: coinUid)
        unfavoritedSubject.send()
    }

    func handleOpen(coinUid: String) {
        var recentCoinUids = recentCoinUids

        if let index = recentCoinUids.firstIndex(of: coinUid) {
            recentCoinUids.remove(at: index)
        }

        recentCoinUids.insert(coinUid, at: 0)
        self.recentCoinUids = Array(recentCoinUids.prefix(5))
    }
}

extension MarketViewModel {
    enum State {
        case idle
        case placeholder(recentFullCoins: [FullCoin], popularFullCoins: [FullCoin])
        case searchResults(fullCoins: [FullCoin])
    }
}
