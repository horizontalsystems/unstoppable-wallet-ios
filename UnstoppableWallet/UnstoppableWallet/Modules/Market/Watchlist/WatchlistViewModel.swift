import Combine

class WatchlistViewModel: ObservableObject {
    private let watchlistManager = App.shared.watchlistManager
    private let page: StatPage
    private let section: StatSection?
    private var cancellables = Set<AnyCancellable>()

    @Published var coinUids: Set<String>

    init(page: StatPage, section: StatSection? = nil) {
        coinUids = Set(watchlistManager.coinUids)

        self.page = page
        self.section = section

        watchlistManager.coinUidsPublisher
            .sink { [weak self] in self?.coinUids = Set($0) }
            .store(in: &cancellables)
    }
}

extension WatchlistViewModel {
    func add(coinUid: String) {
        watchlistManager.add(coinUid: coinUid)
        stat(page: page, section: section, event: .addToWatchlist(coinUid: coinUid))
    }

    func remove(coinUid: String) {
        watchlistManager.remove(coinUid: coinUid)
        stat(page: page, section: section, event: .removeFromWatchlist(coinUid: coinUid))
    }
}
