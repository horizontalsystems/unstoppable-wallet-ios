import MarketKit

struct NftAddressMetadata {
    let collections: [NftCollectionShortMetadata]
    let assets: [NftAssetShortMetadata]
}

struct NftCollectionShortMetadata {
    let providerUid: String
    let name: String
    let thumbnailImageUrl: String?
    let averagePrice7d: NftPrice?
    let averagePrice30d: NftPrice?
}

struct NftAssetShortMetadata {
    let nftUid: NftUid
    let providerCollectionUid: String
    let name: String?
    let previewImageUrl: String?
    let onSale: Bool
    let lastSalePrice: NftPrice?

    var displayName: String {
        name ?? "#\(nftUid.tokenId)"
    }
}
