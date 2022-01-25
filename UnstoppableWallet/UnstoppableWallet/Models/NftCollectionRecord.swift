import Foundation
import GRDB

class NftCollectionRecord: Record {
    let accountId: String
    let slug: String
    let name: String
    let imageUrl: String?
    var floorPrice: NftPriceRecord?

    init(accountId: String, collection: NftCollection) {
        self.accountId = accountId
        slug = collection.slug
        name = collection.name
        imageUrl = collection.imageUrl
        floorPrice = collection.floorPrice.map { NftPriceRecord(price: $0) }

        super.init()
    }

    override class var databaseTableName: String {
        "nftCollectionRecord"
    }

    enum Columns: String, ColumnExpression {
        case accountId, slug, name, imageUrl, floorPriceCoinTypeId, floorPriceValue
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        slug = row[Columns.slug]
        name = row[Columns.name]
        imageUrl = row[Columns.imageUrl]
        floorPrice = NftPriceRecord(coinTypeId: row[Columns.floorPriceCoinTypeId], value: row[Columns.floorPriceValue])

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.slug] = slug
        container[Columns.name] = name
        container[Columns.imageUrl] = imageUrl
        container[Columns.floorPriceCoinTypeId] = floorPrice?.coinTypeId
        container[Columns.floorPriceValue] = floorPrice?.value
    }

}
