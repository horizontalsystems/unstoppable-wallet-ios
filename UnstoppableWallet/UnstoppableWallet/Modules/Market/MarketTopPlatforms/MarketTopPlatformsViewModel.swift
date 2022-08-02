import MarketKit

class MarketTopPlatformsViewModel {
    let service: MarketTopPlatformsService

    let title = "top_platforms.title".localized
    let description = "top_platforms.description".localized
    let imageName = "top_platforms"

    init(service: MarketTopPlatformsService) {
        self.service = service
    }

    func topPlatform(uid: String) -> TopPlatform? {
        service.topPlatforms?.first { $0.blockchain.uid == uid }
    }

}
