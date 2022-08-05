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

    private func tokenQueries(records: [NftPriceRecord]) -> [TokenQuery] {
        Array(Set(records.map { $0.tokenQuery }))
    }

    private func nftPrice(record: NftPriceRecord?, tokens: [Token]) -> NftPrice? {
        guard let record = record else {
            return nil
        }

        guard let token = tokens.first(where: { $0.tokenQuery == record.tokenQuery }) else {
            return nil
        }

        return NftPrice(token: token, value: record.value)
    }

    private func asset(record: NftAssetRecord, tokens: [Token]) -> NftAsset {
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
                lastSalePrice: nftPrice(record: record.lastSalePrice, tokens: tokens),
                onSale: record.onSale,
                orders: []
        )
    }

    private func collection(record: NftCollectionRecord, tokens: [Token]) -> NftCollection {
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
                stats: NftCollectionStats(
                        count: nil,
                        ownerCount: nil,
                        totalSupply: record.totalSupply,
                        averagePrice1d: nil,
                        averagePrice7d: nftPrice(record: record.averagePrice7d, tokens: tokens),
                        averagePrice30d: nftPrice(record: record.averagePrice30d, tokens: tokens),
                        floorPrice: nil,
                        totalVolume: nil,
                        marketCap: nil,
                        volumes: [:],
                        changes: [:]
                ),
                statCharts: nil
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
        let tokens = try marketKit.tokens(queries: tokenQueries(records: priceRecords))

        return NftAssetCollection(
                collections: collectionRecords.map { collection(record: $0, tokens: tokens) },
                assets: assetRecords.map { asset(record: $0, tokens: tokens) }
        )
    }

    func collection(accountId: String, uid: String) throws -> NftCollection? {
        guard let record = try storage.collection(accountId: accountId, uid: uid) else {
            return nil
        }
        let priceRecords = priceRecords(collectionRecords: [record])
        let tokens = try marketKit.tokens(queries: tokenQueries(records: priceRecords))

        return collection(record: record, tokens: tokens)
    }

    func asset(accountId: String, collectionUid: String, tokenId: String) throws -> NftAsset? {
        guard let record = try storage.asset(accountId: accountId, collectionUid: collectionUid, tokenId: tokenId) else {
            return nil
        }
        let priceRecords = priceRecords(assetRecords: [record])
        let tokens = try marketKit.tokens(queries: tokenQueries(records: priceRecords))

        return asset(record: record, tokens: tokens)
    }

    func save(assetCollection: NftAssetCollection, accountId: String) throws {
        try storage.save(
                collections: assetCollection.collections.map { NftCollectionRecord(accountId: accountId, collection: $0) },
                assets: assetCollection.assets.map { NftAssetRecord(accountId: accountId, asset: $0) },
                accountId: accountId
        )
    }

}
