import GRDB

public enum StorageMigrator {
    public static func migrate(dbPool: DatabasePool) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("walletCore.createAccountRecord") { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.id.name, .text).notNull()
                t.column(AccountRecord.Columns.level.name, .integer).notNull().defaults(to: 0)
                t.column(AccountRecord.Columns.name.name, .text).notNull()
                t.column(AccountRecord.Columns.type.name, .text).notNull()
                t.column(AccountRecord.Columns.origin.name, .text).notNull()
                t.column(AccountRecord.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord.Columns.fileBackedUp.name, .boolean).notNull().defaults(to: false)
                t.column(AccountRecord.Columns.wordsKey.name, .text)
                t.column(AccountRecord.Columns.saltKey.name, .text)
                t.column(AccountRecord.Columns.dataKey.name, .text)
                t.column(AccountRecord.Columns.bip39Compliant.name, .boolean)

                t.primaryKey([AccountRecord.Columns.id.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("walletCore.createActiveAccount") { db in
            try db.create(table: ActiveAccount.databaseTableName) { t in
                t.column(ActiveAccount.Columns.level.name, .integer).notNull()
                t.column(ActiveAccount.Columns.accountId.name, .text).notNull()

                t.primaryKey([ActiveAccount.Columns.level.name], onConflict: .replace)
            }
        }

        try migrator.migrate(dbPool)
    }
}
