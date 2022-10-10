import Foundation
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
    let providerLink: String?

    let traits: [Trait]
    let providerTraitLink: String?

    let lastSalePrice: NftPrice?
    let offers: [NftPrice]
    let saleInfo: SaleInfo?

    var displayName: String {
        name ?? "#\(nftUid.tokenId)"
    }

    struct SaleInfo {
        let type: SaleType
        let listings: [SaleListing]
    }

    struct SaleListing {
        let untilDate: Date
        let price: NftPrice
    }

    enum SaleType {
        case onSale
        case onAuction
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
