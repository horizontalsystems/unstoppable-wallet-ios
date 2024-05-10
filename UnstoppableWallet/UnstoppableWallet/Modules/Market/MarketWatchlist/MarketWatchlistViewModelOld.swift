class MarketWatchlistViewModelOld {
    private let service: MarketWatchlistService

    init(service: MarketWatchlistService) {
        self.service = service
    }
}

extension MarketWatchlistViewModelOld {
    func onLoad() {
        service.load()
    }
}
