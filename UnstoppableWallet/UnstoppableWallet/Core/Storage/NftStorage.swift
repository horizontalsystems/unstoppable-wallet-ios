import RxSwift
import MarketKit

class NftStorage {
    private let marketKit: MarketKit.Kit
    private let storage: NftDatabaseStorage

    init(marketKit: MarketKit.Kit, storage: NftDatabaseStorage) {
        self.marketKit = marketKit
        self.storage = storage
    }

    private func coinTypeIds(collectionRecords: [NftCollectionRecord], assetRecords: [NftAssetRecord]) -> [String] {
        var ids = Set<String>()

        for record in collectionRecords {
            if let floorPrice = record.floorPrice {
                ids.insert(floorPrice.coinTypeId)
            }
        }

        for record in assetRecords {
            if let lastPrice = record.lastPrice {
                ids.insert(lastPrice.coinTypeId)
            }
        }

        return Array(ids)
    }

    private func nftPrice(record: NftPriceRecord?, platformCoins: [PlatformCoin]) -> NftPrice? {
        guard let record = record else {
            return nil
        }

        guard let platformCoin = platformCoins.first(where: { $0.coinType.id == record.coinTypeId }) else {
            return nil
        }

        return NftPrice(platformCoin: platformCoin, value: record.value)
    }

}

extension NftStorage {

    func collections(accountId: String) throws -> [NftCollection] {
        let collectionRecords = try storage.collections(accountId: accountId)
        let assetRecords = try storage.assets(accountId: accountId)

        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(collectionRecords: collectionRecords, assetRecords: assetRecords))

        return collectionRecords.map { collectionRecord in
            NftCollection(
                    slug: collectionRecord.slug,
                    name: collectionRecord.name,
                    imageUrl: collectionRecord.imageUrl,
                    floorPrice: nftPrice(record: collectionRecord.floorPrice, platformCoins: platformCoins),
                    assets: assetRecords.filter { $0.collectionSlug == collectionRecord.slug }.map { assetRecord in
                        NftAsset(
                                tokenId: assetRecord.tokenId,
                                name: assetRecord.name,
                                imageUrl: assetRecord.imageUrl,
                                lastPrice: nftPrice(record: assetRecord.lastPrice, platformCoins: platformCoins)
                        )
                    }
            )
        }
    }

    func save(collections: [NftCollection], accountId: String) throws {
        var collectionRecords = [NftCollectionRecord]()
        var assetRecords = [NftAssetRecord]()

        for collection in collections {
            collectionRecords.append(NftCollectionRecord(accountId: accountId, collection: collection))

            for asset in collection.assets {
                assetRecords.append(NftAssetRecord(accountId: accountId, collection: collection, asset: asset))
            }
        }

        try storage.save(collections: collectionRecords, assets: assetRecords, accountId: accountId)
    }

}
