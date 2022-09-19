import Foundation
import MarketKit

struct NftCollectionMetadata {
    let blockchainType: BlockchainType

    let providerUid: String
    let contracts: [String]

    let name: String
    let description: String?
    let imageUrl: String?
    let thumbnailImageUrl: String?
    let externalLink: String?
    let discordLink: String?
    let twitterUsername: String?

    let count: Int?
    let ownerCount: Int?
    let totalSupply: Int?
    let totalVolume: Decimal?
    let floorPrice: NftPrice?
    let marketCap: NftPrice?

    let royalty: Decimal?
    let inceptionDate: Date?

    let volume1d: NftPrice?
    let change1d: Decimal?
    let sales1d: Int?
    let averagePrice1d: NftPrice?

    let volume7d: NftPrice?
    let change7d: Decimal?
    let sales7d: Int?
    let averagePrice7d: NftPrice?

    let volume30d: NftPrice?
    let change30d: Decimal?
    let sales30d: Int?
    let averagePrice30d: NftPrice?
}
