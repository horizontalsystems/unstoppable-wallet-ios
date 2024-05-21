import Combine

class WatchlistViewModel: ObservableObject {
    private let watchlistManager = App.shared.watchlistManager
    private var cancellables = Set<AnyCancellable>()

    @Published var coinUids: Set<String>

    init() {
        coinUids = Set(watchlistManager.coinUids)

        watchlistManager.coinUidsPublisher
            .sink { [weak self] in self?.coinUids = Set($0) }
            .store(in: &cancellables)
    }
}

extension WatchlistViewModel {
    func add(coinUid: String) {
        watchlistManager.add(coinUid: coinUid)
    }

    func remove(coinUid: String) {
        watchlistManager.remove(coinUid: coinUid)
    }
}
