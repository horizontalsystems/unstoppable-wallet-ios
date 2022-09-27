import MarketKit

class MarketNftTopCollectionsViewModel {
    let title = "top_nft_collections.title".localized
    let description = "top_nft_collections.description".localized
    let imageName = "Categories - Top Collections"

    private let service: MarketNftTopCollectionsService

    init(service: MarketNftTopCollectionsService) {
        self.service = service
    }

    func topCollection(uid: String) -> NftTopCollection? {
        service.topCollection(uid: uid)
    }

}
