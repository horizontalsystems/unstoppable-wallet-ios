import MarketKit

class MarketTopPlatformsViewModel {
    let service: MarketTopPlatformsService

    init(service: MarketTopPlatformsService) {
        self.service = service
    }

    func topPlatform(uid: String) -> TopPlatform? {
        service.topPlatforms?.first { $0.blockchain.uid == uid }
    }

}
