import Foundation
import GRDB

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
        averagePrice7d = collection.averagePrice7d.map { NftPriceRecord(price: $0) }
        averagePrice30d = collection.averagePrice30d.map { NftPriceRecord(price: $0) }
        totalSupply = collection.totalSupply

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
        case averagePrice7dCoinTypeId
        case averagePrice7dValue
        case averagePrice30dCoinTypeId
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
        averagePrice7d = NftPriceRecord(coinTypeId: row[Columns.averagePrice7dCoinTypeId], value: row[Columns.averagePrice7dValue])
        averagePrice30d = NftPriceRecord(coinTypeId: row[Columns.averagePrice30dCoinTypeId], value: row[Columns.averagePrice30dValue])
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
        container[Columns.averagePrice7dCoinTypeId] = averagePrice7d?.coinTypeId
        container[Columns.averagePrice7dValue] = averagePrice7d?.value
        container[Columns.averagePrice30dCoinTypeId] = averagePrice30d?.coinTypeId
        container[Columns.averagePrice30dValue] = averagePrice30d?.value
        container[Columns.totalSupply] = totalSupply
    }

}
