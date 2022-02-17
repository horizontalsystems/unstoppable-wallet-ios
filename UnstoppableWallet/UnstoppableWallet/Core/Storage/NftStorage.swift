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

    private func coinTypeIds(records: [NftPriceRecord]) -> [String] {
        Array(Set(records.map { $0.coinTypeId }))
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
                contract: record.contract,
                collectionUid: record.collectionUid,
                tokenId: record.tokenId,
                name: record.name,
                imageUrl: record.imageUrl,
                imagePreviewUrl: record.imagePreviewUrl,
                description: record.description,
                externalLink: record.externalLink,
                permalink: record.permalink,
                traits: record.traits,
                lastSalePrice: nftPrice(record: record.lastSalePrice, platformCoins: platformCoins),
                onSale: record.onSale
        )
    }

    private func collection(record: NftCollectionRecord, platformCoins: [PlatformCoin]) -> NftCollection {
        NftCollection(
                contracts: record.contracts,
                uid: record.uid,
                name: record.name,
                description: record.description,
                imageUrl: record.imageUrl,
                featuredImageUrl: record.featuredImageUrl,
                externalUrl: record.externalUrl,
                discordUrl: record.discordUrl,
                twitterUsername: record.twitterUsername,
                averagePrice7d: nftPrice(record: record.averagePrice7d, platformCoins: platformCoins),
                averagePrice30d: nftPrice(record: record.averagePrice30d, platformCoins: platformCoins),
                totalSupply: record.totalSupply
        )
    }

    private func priceRecords(collectionRecords: [NftCollectionRecord]) -> [NftPriceRecord] {
        collectionRecords.compactMap { $0.averagePrice7d } + collectionRecords.compactMap { $0.averagePrice30d }
    }

    private func priceRecords(assetRecords: [NftAssetRecord]) -> [NftPriceRecord] {
        assetRecords.compactMap { $0.lastSalePrice }
    }

}

extension NftStorage {

    func assetCollection(accountId: String) throws -> NftAssetCollection {
        let collectionRecords = try storage.collections(accountId: accountId)
        let assetRecords = try storage.assets(accountId: accountId)

        let priceRecords = priceRecords(collectionRecords: collectionRecords) + priceRecords(assetRecords: assetRecords)
        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(records: priceRecords))

        return NftAssetCollection(
                collections: collectionRecords.map { collection(record: $0, platformCoins: platformCoins) },
                assets: assetRecords.map { asset(record: $0, platformCoins: platformCoins) }
        )
    }

    func collection(accountId: String, uid: String) throws -> NftCollection? {
        guard let record = try storage.collection(accountId: accountId, uid: uid) else {
            return nil
        }
        let priceRecords = priceRecords(collectionRecords: [record])
        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(records: priceRecords))

        return collection(record: record, platformCoins: platformCoins)
    }

    func asset(accountId: String, collectionUid: String, tokenId: String) throws -> NftAsset? {
        guard let record = try storage.asset(accountId: accountId, collectionUid: collectionUid, tokenId: tokenId) else {
            return nil
        }
        let priceRecords = priceRecords(assetRecords: [record])
        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds(records: priceRecords))

        return asset(record: record, platformCoins: platformCoins)
    }

    func save(assetCollection: NftAssetCollection, accountId: String) throws {
        try storage.save(
                collections: assetCollection.collections.map { NftCollectionRecord(accountId: accountId, collection: $0) },
                assets: assetCollection.assets.map { NftAssetRecord(accountId: accountId, asset: $0) },
                accountId: accountId
        )
    }

}
