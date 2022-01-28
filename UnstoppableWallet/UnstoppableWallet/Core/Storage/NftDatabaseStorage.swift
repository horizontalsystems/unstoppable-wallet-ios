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
                t.column(NftCollectionRecord.Columns.slug.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.name.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.imageUrl.name, .text)
                t.column(NftCollectionRecord.Columns.floorPriceCoinTypeId.name, .text)
                t.column(NftCollectionRecord.Columns.floorPriceValue.name, .text)

                t.primaryKey([NftCollectionRecord.Columns.accountId.name, NftCollectionRecord.Columns.slug.name], onConflict: .replace)
            }

            try db.create(table: NftAssetRecord.databaseTableName) { t in
                t.column(NftAssetRecord.Columns.accountId.name, .text).notNull()
                t.column(NftAssetRecord.Columns.collectionSlug.name, .text).notNull()
                t.column(NftAssetRecord.Columns.tokenId.name, .text).notNull()
                t.column(NftAssetRecord.Columns.name.name, .text)
                t.column(NftAssetRecord.Columns.imageUrl.name, .text).notNull()
                t.column(NftAssetRecord.Columns.lastPriceCoinTypeId.name, .text)
                t.column(NftAssetRecord.Columns.lastPriceValue.name, .text)

                t.primaryKey([NftAssetRecord.Columns.accountId.name, NftAssetRecord.Columns.collectionSlug.name, NftAssetRecord.Columns.tokenId.name], onConflict: .replace)
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

    func save(collections: [NftCollectionRecord], assets: [NftAssetRecord], accountId: String) throws {
        _ = try dbPool.write { db in
            try NftCollectionRecord.filter(NftAssetRecord.Columns.accountId == accountId).deleteAll(db)
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
