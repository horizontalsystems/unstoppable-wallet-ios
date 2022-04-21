import Foundation

struct NftCollectionStats {
    let totalSupply: Int
    let averagePrice7d: NftPrice?
    let averagePrice30d: NftPrice?
    let floorPrice: NftPrice?
    let totalVolume: Decimal?
    let marketCap: NftPrice?

    let oneDayChange: Decimal?
    let sevenDayChange: Decimal?
    let thirtyDayChange: Decimal?

    let oneDayVolume: NftPrice?
    let sevenDayVolume: NftPrice?
    let thirtyDayVolume: NftPrice?
}
