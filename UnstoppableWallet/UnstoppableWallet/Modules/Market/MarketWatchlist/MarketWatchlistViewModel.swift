class MarketWatchlistViewModel {
    private let service: MarketWatchlistService

    init(service: MarketWatchlistService) {
        self.service = service
    }

}

extension MarketWatchlistViewModel {

    func onLoad() {
        service.load()
    }

}
