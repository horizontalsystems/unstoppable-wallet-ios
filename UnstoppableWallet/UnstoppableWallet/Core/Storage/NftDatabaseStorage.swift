import Foundation
import GRDB

class NftDatabaseStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create NftCollectionRecord and NftAssetRecord") { db in
            try db.create(table: NftCollectionRecord.databaseTableName) { t in
                t.column(NftCollectionRecord.Columns.accountId.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.contracts.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.uid.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.name.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.description.name, .text)
                t.column(NftCollectionRecord.Columns.imageUrl.name, .text)
                t.column(NftCollectionRecord.Columns.featuredImageUrl.name, .text)
                t.column(NftCollectionRecord.Columns.externalUrl.name, .text)
                t.column(NftCollectionRecord.Columns.discordUrl.name, .text)
                t.column(NftCollectionRecord.Columns.twitterUsername.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice7dCoinTypeId.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice7dValue.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice30dCoinTypeId.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice30dValue.name, .text)
                t.column(NftCollectionRecord.Columns.totalSupply.name, .integer).notNull()

                t.primaryKey([NftCollectionRecord.Columns.accountId.name, NftCollectionRecord.Columns.uid.name], onConflict: .replace)
            }

            try db.create(table: NftAssetRecord.databaseTableName) { t in
                t.column(NftAssetRecord.Columns.accountId.name, .text).notNull()
                t.column(NftAssetRecord.Columns.contractAddress.name, .text).notNull()
                t.column(NftAssetRecord.Columns.contractSchemaName.name, .text).notNull()
                t.column(NftAssetRecord.Columns.collectionUid.name, .text).notNull()
                t.column(NftAssetRecord.Columns.tokenId.name, .text).notNull()
                t.column(NftAssetRecord.Columns.name.name, .text)
                t.column(NftAssetRecord.Columns.imageUrl.name, .text)
                t.column(NftAssetRecord.Columns.imagePreviewUrl.name, .text)
                t.column(NftAssetRecord.Columns.description.name, .text)
                t.column(NftAssetRecord.Columns.externalLink.name, .text)
                t.column(NftAssetRecord.Columns.permalink.name, .text)
                t.column(NftAssetRecord.Columns.traits.name, .text).notNull()
                t.column(NftAssetRecord.Columns.lastSalePriceCoinTypeId.name, .text)
                t.column(NftAssetRecord.Columns.lastSalePriceValue.name, .text)
                t.column(NftAssetRecord.Columns.onSale.name, .boolean)

                t.primaryKey([NftAssetRecord.Columns.accountId.name, NftAssetRecord.Columns.contractAddress.name, NftAssetRecord.Columns.tokenId.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension NftDatabaseStorage {

    func collections(accountId: String) throws -> [NftCollectionRecord] {
        try dbPool.read { db in
            try NftCollectionRecord.filter(NftCollectionRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func assets(accountId: String) throws -> [NftAssetRecord] {
        try dbPool.read { db in
            try NftAssetRecord.filter(NftAssetRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func collection(accountId: String, uid: String) throws -> NftCollectionRecord? {
        try dbPool.read { db in
            try NftCollectionRecord.filter(NftCollectionRecord.Columns.accountId == accountId && NftCollectionRecord.Columns.uid == uid).fetchOne(db)
        }
    }

    func asset(accountId: String, collectionUid: String, tokenId: String) throws -> NftAssetRecord? {
        try dbPool.read { db in
            try NftAssetRecord.filter(NftAssetRecord.Columns.accountId == accountId && NftAssetRecord.Columns.collectionUid == collectionUid && NftAssetRecord.Columns.tokenId == tokenId).fetchOne(db)
        }
    }

    func save(collections: [NftCollectionRecord], assets: [NftAssetRecord], accountId: String) throws {
        _ = try dbPool.write { db in
            try NftCollectionRecord.filter(NftCollectionRecord.Columns.accountId == accountId).deleteAll(db)
            try NftAssetRecord.filter(NftAssetRecord.Columns.accountId == accountId).deleteAll(db)

            for collection in collections {
                try collection.insert(db)
            }
            for asset in assets {
                try asset.insert(db)
            }
        }
    }

}
