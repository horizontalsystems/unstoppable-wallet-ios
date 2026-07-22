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

        migrator.registerMigration("create ZcashTransparentAlert") { db in
            try db.create(table: ZcashTransparentAlertState.databaseTableName) { t in
                t.column(ZcashTransparentAlertState.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(ZcashTransparentAlertState.Columns.lastAlertedBalance.name, .text).notNull()
            }
        }

        migrator.registerMigration("add orchard to ZcashBalance") { db in
            try db.alter(table: ZcashBalanceData.databaseTableName) { t in
                t.add(column: ZcashBalanceData.Columns.orchard.name, .text).notNull().defaults(to: "0")
            }
        }

        migrator.registerMigration("create ZcashMigrationTx") { db in
            try db.create(table: ZcashMigrationTx.databaseTableName) { t in
                t.column(ZcashMigrationTx.Columns.txId.name, .text)
                t.column(ZcashMigrationTx.Columns.accountId.name, .text).notNull()
                t.column(ZcashMigrationTx.Columns.createdAt.name, .datetime).notNull()
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

extension ZcashAdapterStorage {
    func save(state: ZcashTransparentAlertState) throws {
        try dbPool.write { db in
            try state.insert(db)
        }
    }

    func alertState(id: String) throws -> ZcashTransparentAlertState? {
        try dbPool.read { db in
            try ZcashTransparentAlertState
                .filter(ZcashTransparentAlertState.Columns.id == id)
                .fetchOne(db)
        }
    }

    func deleteAlertState(id: String) throws {
        _ = try dbPool.write { db in
            try ZcashTransparentAlertState
                .filter(ZcashTransparentAlertState.Columns.id == id)
                .deleteAll(db)
        }
    }
}

extension ZcashAdapterStorage {
    func save(migrationTx: ZcashMigrationTx) throws {
        try dbPool.write { db in
            try migrationTx.insert(db)
        }
    }

    func migrationTxIds(accountId: String) throws -> [String] {
        try dbPool.read { db in
            try ZcashMigrationTx
                .filter(ZcashMigrationTx.Columns.accountId == accountId)
                .fetchAll(db)
                .compactMap(\.txId)
        }
    }

    func latestMigrationDate(accountId: String) throws -> Date? {
        try dbPool.read { db in
            try ZcashMigrationTx
                .filter(ZcashMigrationTx.Columns.accountId == accountId)
                .order(ZcashMigrationTx.Columns.createdAt.desc)
                .fetchOne(db)?
                .createdAt
        }
    }

    func deleteMigrationTxs(accountId: String) throws {
        _ = try dbPool.write { db in
            try ZcashMigrationTx
                .filter(ZcashMigrationTx.Columns.accountId == accountId)
                .deleteAll(db)
        }
    }
}
