import Combine

class FavoritesViewModel: ObservableObject {
    private let favoritesManager = App.shared.favoritesManager
    private var cancellables = Set<AnyCancellable>()

    @Published var coinUids: Set<String>

    init() {
        coinUids = favoritesManager.coinUids

        favoritesManager.coinUidsPublisher
            .sink { [weak self] in self?.coinUids = $0 }
            .store(in: &cancellables)
    }
}

extension FavoritesViewModel {
    func add(coinUid: String) {
        favoritesManager.add(coinUid: coinUid)
    }

    func remove(coinUid: String) {
        favoritesManager.remove(coinUid: coinUid)
    }
}
