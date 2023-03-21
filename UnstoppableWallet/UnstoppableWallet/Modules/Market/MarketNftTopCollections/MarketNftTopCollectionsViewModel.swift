import MarketKit

class MarketNftTopCollectionsViewModel {
    private let service: MarketNftTopCollectionsService

    init(service: MarketNftTopCollectionsService) {
        self.service = service
    }

    func topCollection(uid: String) -> NftTopCollection? {
        service.topCollection(uid: uid)
    }

}
