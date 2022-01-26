import Foundation
import GRDB

class NftAssetRecord: Record {
    let accountId: String
    let collectionSlug: String
    let tokenId: Decimal
    let name: String?
    let imageUrl: String?
    let lastPrice: NftPriceRecord?

    init(accountId: String, collection: NftCollection, asset: NftAsset) {
        self.accountId = accountId
        collectionSlug = collection.slug
        tokenId = asset.tokenId
        name = asset.name
        imageUrl = asset.imageUrl
        lastPrice = asset.lastPrice.map { NftPriceRecord(price: $0) }

        super.init()
    }

    override class var databaseTableName: String {
        "nftAssetRecord"
    }

    enum Columns: String, ColumnExpression {
        case accountId, collectionSlug, tokenId, name, imageUrl, lastPriceCoinTypeId, lastPriceValue
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        collectionSlug = row[Columns.collectionSlug]
        tokenId = row[Columns.tokenId]
        name = row[Columns.name]
        imageUrl = row[Columns.imageUrl]
        lastPrice = NftPriceRecord(coinTypeId: row[Columns.lastPriceCoinTypeId], value: row[Columns.lastPriceValue])

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.collectionSlug] = collectionSlug
        container[Columns.tokenId] = tokenId
        container[Columns.name] = name
        container[Columns.imageUrl] = imageUrl
        container[Columns.lastPriceCoinTypeId] = lastPrice?.coinTypeId
        container[Columns.lastPriceValue] = lastPrice?.value
    }

}
