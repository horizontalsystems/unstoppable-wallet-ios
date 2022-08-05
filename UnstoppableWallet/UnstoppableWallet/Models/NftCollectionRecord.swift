import Foundation
import GRDB
import MarketKit

class NftCollectionRecord: Record {
    let accountId: String

    let contracts: [NftCollection.Contract]
    let uid: String
    let name: String
    let description: String?
    let imageUrl: String?
    let featuredImageUrl: String?
    let externalUrl: String?
    let discordUrl: String?
    let twitterUsername: String?
    let averagePrice7d: NftPriceRecord?
    let averagePrice30d: NftPriceRecord?
    let totalSupply: Int

    init(accountId: String, collection: NftCollection) {
        self.accountId = accountId
        contracts = collection.contracts
        uid = collection.uid
        name = collection.name
        description = collection.description
        imageUrl = collection.imageUrl
        featuredImageUrl = collection.featuredImageUrl
        externalUrl = collection.externalUrl
        discordUrl = collection.discordUrl
        twitterUsername = collection.twitterUsername
        averagePrice7d = collection.stats.averagePrice7d.map { NftPriceRecord(price: $0) }
        averagePrice30d = collection.stats.averagePrice30d.map { NftPriceRecord(price: $0) }
        totalSupply = collection.stats.totalSupply

        super.init()
    }

    override class var databaseTableName: String {
        "nftCollectionRecord"
    }

    enum Columns: String, ColumnExpression {
        case accountId
        case contracts
        case uid
        case name
        case description
        case imageUrl
        case featuredImageUrl
        case externalUrl
        case discordUrl
        case twitterUsername
        case averagePrice7dTokenQueryId
        case averagePrice7dValue
        case averagePrice30dTokenQueryId
        case averagePrice30dValue
        case totalSupply
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        contracts = [NftCollection.Contract](JSONString: row[Columns.contracts]) ?? []
        uid = row[Columns.uid]
        name = row[Columns.name]
        description = row[Columns.description]
        imageUrl = row[Columns.imageUrl]
        featuredImageUrl = row[Columns.featuredImageUrl]
        externalUrl = row[Columns.externalUrl]
        discordUrl = row[Columns.discordUrl]
        twitterUsername = row[Columns.twitterUsername]
        averagePrice7d = NftPriceRecord(tokenQueryId: row[Columns.averagePrice7dTokenQueryId], value: row[Columns.averagePrice7dValue])
        averagePrice30d = NftPriceRecord(tokenQueryId: row[Columns.averagePrice30dTokenQueryId], value: row[Columns.averagePrice30dValue])
        totalSupply = row[Columns.totalSupply]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.contracts] = contracts.toJSONString()
        container[Columns.uid] = uid
        container[Columns.name] = name
        container[Columns.description] = description
        container[Columns.imageUrl] = imageUrl
        container[Columns.featuredImageUrl] = featuredImageUrl
        container[Columns.externalUrl] = externalUrl
        container[Columns.discordUrl] = discordUrl
        container[Columns.twitterUsername] = twitterUsername
        container[Columns.averagePrice7dTokenQueryId] = averagePrice7d?.tokenQuery.id
        container[Columns.averagePrice7dValue] = averagePrice7d?.value
        container[Columns.averagePrice30dTokenQueryId] = averagePrice30d?.tokenQuery.id
        container[Columns.averagePrice30dValue] = averagePrice30d?.value
        container[Columns.totalSupply] = totalSupply
    }

}
