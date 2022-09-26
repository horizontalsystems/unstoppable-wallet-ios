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

    private func asset(record: NftAssetRecord, tokens: [Token]) -> NftAssetShortMetadata {
        NftAssetShortMetadata(
                nftUid: record.nftUid,
                providerCollectionUid: record.providerCollectionUid,
                name: record.name,
                previewImageUrl: record.previewImageUrl,
                onSale: record.onSale,
                lastSalePrice: nftPrice(record: record.lastSalePrice, tokens: tokens)
        )
    }

    private func collection(record: NftCollectionRecord, tokens: [Token]) -> NftCollectionShortMetadata {
        NftCollectionShortMetadata(
                providerUid: record.providerUid,
                name: record.name,
                thumbnailImageUrl: record.thumbnailImageUrl,
                averagePrice7d: nftPrice(record: record.averagePrice7d, tokens: tokens),
                averagePrice30d: nftPrice(record: record.averagePrice30d, tokens: tokens)
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

    func addressMetadata(nftKey: NftKey) -> NftAddressMetadata? {
        do {
            let collectionRecords = try storage.collections(blockchainTypeUid: nftKey.blockchainType.uid, accountId: nftKey.account.id)
            let assetRecords = try storage.assets(blockchainTypeUid: nftKey.blockchainType.uid, accountId: nftKey.account.id)

            let priceRecords = priceRecords(collectionRecords: collectionRecords) + priceRecords(assetRecords: assetRecords)
            let tokens = try marketKit.tokens(queries: tokenQueries(records: priceRecords))

            return NftAddressMetadata(
                    collections: collectionRecords.map { collection(record: $0, tokens: tokens) },
                    assets: assetRecords.map { asset(record: $0, tokens: tokens) }
            )
        } catch {
            print("Could not fetch NftAddressMetadata: \(error)")
            return nil
        }
    }

    func assetShortMetadata(nftUid: NftUid) -> NftAssetShortMetadata? {
        do {
            guard let assetRecord = try storage.asset(nftUid: nftUid) else {
                return nil
            }

            return asset(record: assetRecord, tokens: [])
        } catch {
            print("Could not fetch NftAssetRecord: \(error)")
            return nil
        }
    }

    func save(addressMetadata: NftAddressMetadata, nftKey: NftKey) {
        do {
            try storage.save(
                    collections: addressMetadata.collections.map { NftCollectionRecord(blockchainTypeUid: nftKey.blockchainType.uid, accountId: nftKey.account.id, collection: $0) },
                    assets: addressMetadata.assets.map { NftAssetRecord(blockchainTypeUid: nftKey.blockchainType.uid, accountId: nftKey.account.id, asset: $0) },
                    blockchainTypeUid: nftKey.blockchainType.uid,
                    accountId: nftKey.account.id
            )
        } catch {
            print("Could not save NftAddressMetadata: \(error)")
        }
    }

    func lastSyncTimestamp(nftKey: NftKey) -> TimeInterval? {
        do {
            return try storage.metadataSyncRecord(blockchainTypeUid: nftKey.blockchainType.uid, accountId: nftKey.account.id)?.lastSyncTimestamp
        } catch {
            print("Could not fetch NftMetadataSyncRecord: \(error)")
            return nil
        }
    }

    func save(lastSyncTimestamp: TimeInterval, nftKey: NftKey) {
        do {
            let record = NftMetadataSyncRecord(blockchainTypeUid: nftKey.blockchainType.uid, accountId: nftKey.account.id, lastSyncTimestamp: lastSyncTimestamp)
            try storage.save(metadataSyncRecord: record)
        } catch {
            print("Could not save NftMetadataSyncRecord: \(error)")
        }
    }

    func assetsBriefMetadata(nftUids: Set<NftUid>) -> [NftAssetBriefMetadata] {
        do {
            return try storage.assetsBriefMetadata(nftUids: nftUids)
        } catch {
            print("Could not fetch [NftAssetBriefMetadata]: \(error)")
            return []
        }
    }

    func save(assetsBriefMetadata: [NftAssetBriefMetadata]) {
        do {
            try storage.save(assetsBriefMetadata: assetsBriefMetadata)
        } catch {
            print("Could not save [NftAssetBriefMetadata]: \(error)")
        }
    }

}
