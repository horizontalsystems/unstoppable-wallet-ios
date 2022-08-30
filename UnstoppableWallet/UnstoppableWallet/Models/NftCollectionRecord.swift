import Foundation
import GRDB
import MarketKit

class NftCollectionRecord: Record {
    let blockchainTypeUid: String
    let accountId: String

    let providerUid: String
    let name: String
    let thumbnailImageUrl: String?
    let averagePrice7d: NftPriceRecord?
    let averagePrice30d: NftPriceRecord?

    init(blockchainTypeUid: String, accountId: String, collection: NftCollectionShortMetadata) {
        self.blockchainTypeUid = blockchainTypeUid
        self.accountId = accountId
        providerUid = collection.providerUid
        name = collection.name
        thumbnailImageUrl = collection.thumbnailImageUrl
        averagePrice7d = collection.averagePrice7d.map { NftPriceRecord(price: $0) }
        averagePrice30d = collection.averagePrice30d.map { NftPriceRecord(price: $0) }

        super.init()
    }

    override class var databaseTableName: String {
        "nftCollectionRecord"
    }

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid
        case accountId
        case providerUid
        case name
        case thumbnailImageUrl
        case averagePrice7dTokenQueryId
        case averagePrice7dValue
        case averagePrice30dTokenQueryId
        case averagePrice30dValue
    }

    required init(row: Row) {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        accountId = row[Columns.accountId]
        providerUid = row[Columns.providerUid]
        name = row[Columns.name]
        thumbnailImageUrl = row[Columns.thumbnailImageUrl]
        averagePrice7d = NftPriceRecord(tokenQueryId: row[Columns.averagePrice7dTokenQueryId], value: row[Columns.averagePrice7dValue])
        averagePrice30d = NftPriceRecord(tokenQueryId: row[Columns.averagePrice30dTokenQueryId], value: row[Columns.averagePrice30dValue])

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.accountId] = accountId
        container[Columns.providerUid] = providerUid
        container[Columns.name] = name
        container[Columns.thumbnailImageUrl] = thumbnailImageUrl
        container[Columns.averagePrice7dTokenQueryId] = averagePrice7d?.tokenQuery.id
        container[Columns.averagePrice7dValue] = averagePrice7d?.value
        container[Columns.averagePrice30dTokenQueryId] = averagePrice30d?.tokenQuery.id
        container[Columns.averagePrice30dValue] = averagePrice30d?.value
    }

}
