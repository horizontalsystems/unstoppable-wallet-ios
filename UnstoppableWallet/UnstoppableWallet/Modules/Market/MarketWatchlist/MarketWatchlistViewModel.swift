class MarketWatchlistViewModel {
    private let service: MarketWatchlistService

    init(service: MarketWatchlistService) {
        self.service = service
    }

}

extension MarketWatchlistViewModel {

    func onUnwatch(index: Int) {
        service.unwatch(index: index)
    }

}
