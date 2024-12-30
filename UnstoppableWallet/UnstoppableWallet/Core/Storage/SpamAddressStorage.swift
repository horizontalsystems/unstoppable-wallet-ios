import Foundation
import GRDB

class SpamAddressStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create SpamAddress") { db in
            try db.create(table: SpamAddress.databaseTableName) { t in
                t.column(SpamAddress.Columns.raw.name, .text).notNull()
                t.column(SpamAddress.Columns.domain.name, .text)
                t.column(SpamAddress.Columns.blockchainTypeUid.name, .text)
                t.column(SpamAddress.Columns.transactionHash.name, .blob).notNull()

                t.primaryKey([SpamAddress.Columns.transactionHash.name, SpamAddress.Columns.raw.name], onConflict: .ignore)
            }
        }

        migrator.registerMigration("create SpamScanState") { db in
            try db.create(table: SpamScanState.databaseTableName) { t in
                t.column(SpamScanState.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(SpamScanState.Columns.accountUid.name, .text).notNull()
                t.column(SpamScanState.Columns.lastTransactionHash.name, .blob).notNull()

                t.primaryKey([SpamScanState.Columns.blockchainTypeUid.name, SpamScanState.Columns.accountUid.name], onConflict: .ignore)
            }
        }

        return migrator
    }
}

extension SpamAddressStorage {
    func save(spamAddresses: [SpamAddress]) throws {
        try dbPool.write { db in
            for spamAddress in spamAddresses {
                try spamAddress.insert(db)
            }
        }
    }

    func find(address: String) throws -> SpamAddress? {
        try dbPool.read { db in
            try SpamAddress.filter(SpamAddress.Columns.raw == address).fetchOne(db)
        }
    }

    func isSpam(transactionHash: Data) throws -> Bool {
        try dbPool.read { db in
            try SpamAddress.filter(SpamAddress.Columns.transactionHash == transactionHash).fetchOne(db) != nil
        }
    }

    func save(spamScanState: SpamScanState) throws {
        try dbPool.write { db in
            try spamScanState.save(db)
        }
    }

    func find(blockchainTypeUid: String, accountUid: String) throws -> SpamScanState? {
        try dbPool.read { db in
            try SpamScanState.filter(SpamScanState.Columns.blockchainTypeUid == blockchainTypeUid && SpamScanState.Columns.accountUid == accountUid).fetchOne(db)
        }
    }

    func clear() throws {
        _ = try dbPool.write { db in
            try SpamAddress.deleteAll(db)
        }
    }
}
