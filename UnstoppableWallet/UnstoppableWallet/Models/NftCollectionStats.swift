import Foundation

struct NftCollectionStats {
    let totalSupply: Int
    let averagePrice7d: NftPrice?
    let averagePrice30d: NftPrice?
    let floorPrice: NftPrice?
    let totalVolume: Decimal?
    let priceChange: Decimal?
    let marketCap: NftPrice?
    let oneDayVolume: NftPrice?
    let sevenDayVolume: NftPrice?
    let thirtyDayVolume: NftPrice?
}
