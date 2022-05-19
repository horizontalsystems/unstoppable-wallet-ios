import Foundation
import MarketKit

struct NftCollectionStats {
    let totalSupply: Int
    let averagePrice7d: NftPrice?
    let averagePrice30d: NftPrice?
    let floorPrice: NftPrice?
    let totalVolume: Decimal?
    let marketCap: NftPrice?

    let changes: [HsTimePeriod: Decimal]
    let volumes: [HsTimePeriod: NftPrice]
}
