class MarketNftTopCollectionsViewModel {
    let title = "top_nft_collections.title".localized
    let description = "top_nft_collections.description".localized
    let imageName = "Categories - Top Collections"

    let service: MarketNftTopCollectionsService

    init(service: MarketNftTopCollectionsService) {
        self.service = service
    }

    func collection(uid: String) -> NftCollection? {
        service.collection(uid: uid)
    }

}
