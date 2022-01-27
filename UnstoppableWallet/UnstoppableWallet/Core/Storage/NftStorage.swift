import Foundation
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

    private func asset(record: NftAssetRecord, platformCoins: [PlatformCoin]) -> NftAsset {
        NftAsset(
                tokenId: record.tokenId,
                name: record.name,
                imageUrl: record.imageUrl,
                lastPrice: nftPrice(record: record.lastPrice, platformCoins: platformCoins)
        )
    }

    private func collection(record: NftCollectionRecord, assetRecords: [NftAssetRecord], platformCoins: [PlatformCoin]) -> NftCollection {
        NftCollection(
                slug: record.slug,
                name: record.name,
                imageUrl: record.imageUrl,
                floorPrice: nftPrice(record: record.floorPrice, platformCoins: platformCoins),
                assets: assetRecords.filter { $0.collectionSlug == record.slug }.map { asset(record: $0, platformCoins: platformCoins) }
        )
    }

}

extension NftStorage {

    func collections(accountId: String) throws -> [NftCollection] {
        let collectionRecords = try storage.collections(accountId: accountId)
        let assetRecords = try storage.assets(accountId: accountId)
        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(collectionRecords: collectionRecords, assetRecords: assetRecords))

        return collectionRecords.map { collection(record: $0, assetRecords: assetRecords, platformCoins: platformCoins) }
    }

    func collection(accountId: String, slug: String) throws -> NftCollection? {
        guard let collectionRecord = try storage.collection(accountId: accountId, slug: slug) else {
            return nil
        }

        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(collectionRecords: [collectionRecord], assetRecords: []))
        return collection(record: collectionRecord, assetRecords: [], platformCoins: platformCoins)
    }

    func asset(accountId: String, collectionSlug: String, tokenId: Decimal) throws -> NftAsset? {
        guard let assetRecord = try storage.asset(accountId: accountId, collectionSlug: collectionSlug, tokenId: tokenId) else {
            return nil
        }

        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(collectionRecords: [], assetRecords: [assetRecord]))
        return asset(record: assetRecord, platformCoins: platformCoins)
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
