import MarketKit

struct NftAssetMetadata {
    let nftUid: NftUid
    let providerCollectionUid: String

    let name: String?
    let imageUrl: String?
    let previewImageUrl: String?
    let description: String?
    let nftType: String
    let externalLink: String?
    let providerLink: ProviderLink?

    let traits: [Trait]
    let providerTraitLink: String?

    let lastSalePrice: NftPrice?
    let bestOffer: NftPrice?
    let saleInfo: SaleInfo?

    struct SaleInfo {
        let untilDate: Date
        let type: SalePriceType
        let price: NftPrice?
    }

    enum SalePriceType {
        case buyNow
        case topBid
        case minimumBid
    }

    struct Trait {
        let type: String
        let value: String
        let count: Int
    }

}

struct ProviderLink {
    let title: String
    let url: String
}
