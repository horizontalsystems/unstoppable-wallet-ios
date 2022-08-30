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

        migrator.registerMigration("Recreate NftCollectionRecord and NftAssetRecord for metadata") { db in
            if try db.tableExists("nftCollectionRecord") {
                try db.drop(table: "nftCollectionRecord")
            }
            if try db.tableExists("nftAssetRecord") {
                try db.drop(table: "nftAssetRecord")
            }

            try db.create(table: NftCollectionRecord.databaseTableName) { t in
                t.column(NftCollectionRecord.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.accountId.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.uids.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.providerUid.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.name.name, .text).notNull()
                t.column(NftCollectionRecord.Columns.thumbnailImageUrl.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice7dTokenQueryId.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice7dValue.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice30dTokenQueryId.name, .text)
                t.column(NftCollectionRecord.Columns.averagePrice30dValue.name, .text)

                t.primaryKey([NftCollectionRecord.Columns.blockchainTypeUid.name, NftCollectionRecord.Columns.accountId.name, NftCollectionRecord.Columns.providerUid.name], onConflict: .replace)
            }

            try db.create(table: NftAssetRecord.databaseTableName) { t in
                t.column(NftAssetRecord.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(NftAssetRecord.Columns.accountId.name, .text).notNull()
                t.column(NftAssetRecord.Columns.nftUid.name, .text).notNull()
                t.column(NftAssetRecord.Columns.providerCollectionUid.name, .text).notNull()
                t.column(NftAssetRecord.Columns.name.name, .text)
                t.column(NftAssetRecord.Columns.previewImageUrl.name, .text)
                t.column(NftAssetRecord.Columns.onSale.name, .boolean)
                t.column(NftAssetRecord.Columns.lastSalePriceTokenQueryId.name, .text)
                t.column(NftAssetRecord.Columns.lastSalePriceValue.name, .text)

                t.primaryKey([NftAssetRecord.Columns.blockchainTypeUid.name, NftAssetRecord.Columns.accountId.name, NftAssetRecord.Columns.nftUid.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension NftDatabaseStorage {

    func collections(blockchainTypeUid: String, accountId: String) throws -> [NftCollectionRecord] {
        try dbPool.read { db in
            try NftCollectionRecord
                    .filter(NftCollectionRecord.Columns.blockchainTypeUid == blockchainTypeUid && NftCollectionRecord.Columns.accountId == accountId)
                    .fetchAll(db)
        }
    }

    func assets(blockchainTypeUid: String, accountId: String) throws -> [NftAssetRecord] {
        try dbPool.read { db in
            try NftAssetRecord
                    .filter(NftAssetRecord.Columns.blockchainTypeUid == blockchainTypeUid && NftAssetRecord.Columns.accountId == accountId)
                    .fetchAll(db)
        }
    }

    func save(collections: [NftCollectionRecord], assets: [NftAssetRecord], blockchainTypeUid: String, accountId: String) throws {
        _ = try dbPool.write { db in
            try NftCollectionRecord
                    .filter(NftCollectionRecord.Columns.blockchainTypeUid == blockchainTypeUid && NftCollectionRecord.Columns.accountId == accountId)
                    .deleteAll(db)

            try NftAssetRecord
                    .filter(NftAssetRecord.Columns.blockchainTypeUid == blockchainTypeUid && NftAssetRecord.Columns.accountId == accountId)
                    .deleteAll(db)

            for collection in collections {
                try collection.insert(db)
            }
            for asset in assets {
                try asset.insert(db)
            }
        }
    }

}
