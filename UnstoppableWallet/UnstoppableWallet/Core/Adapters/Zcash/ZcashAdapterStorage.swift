import Foundation
import GRDB

class ZcashAdapterStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create ZcashBalance") { db in
            try db.create(table: ZcashBalanceData.databaseTableName) { t in
                t.column(ZcashBalanceData.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(ZcashBalanceData.Columns.full.name, .text).notNull()
                t.column(ZcashBalanceData.Columns.available.name, .text).notNull()
                t.column(ZcashBalanceData.Columns.transparent.name, .text).notNull()
            }
        }

        return migrator
    }
}

extension ZcashAdapterStorage {
    func save(balanceData: ZcashBalanceData) throws {
        try dbPool.write { db in
            try balanceData.insert(db)
        }
    }

    func balanceData(id: String) throws -> ZcashBalanceData? {
        try dbPool.read { db in
            try ZcashBalanceData
                .filter(ZcashBalanceData.Columns.id == id)
                .fetchOne(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbPool.write { db in
            try ZcashBalanceData
                .filter(ZcashBalanceData.Columns.id == id)
                .deleteAll(db)
        }
    }

    func clear() throws {
        _ = try dbPool.write { db in
            try ZcashBalanceData.deleteAll(db)
        }
    }
}
