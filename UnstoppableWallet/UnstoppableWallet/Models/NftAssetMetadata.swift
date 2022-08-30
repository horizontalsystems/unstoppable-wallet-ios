import MarketKit

struct NftAssetMetadata {
    let name: String?
    let imageUrl: String?
    let description: String?
    let nftType: String
    let websiteLink: String?
    let providerLink: ProviderLink?

    let traits: [Trait]
    let providerTraitLink: String?

    let lastSalePrice: NftPrice?
    let bestOffer: NftPrice?
    let saleInfo: SaleInfo?

    let providerCollectionUid: String
    let collectionName: String
    let collectionTotalSupply: Int
    let collectionDiscordLink: String?
    let collectionTwitterUsername: String?
    let collectionAveragePrice7d: NftPrice?
    let collectionAveragePrice30d: NftPrice?
    let collectionFloorPrice: NftPrice?

    struct ProviderLink {
        let title: String
        let url: String
    }

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
