import GRDB

class WCSessionStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create wcnSession") { db in
            try db.create(table: WCSessionRecord.databaseTableName) { t in
                t.primaryKey(WCSessionRecord.Columns.topic.name, .text, onConflict: .replace)
                t.column(WCSessionRecord.Columns.accountId.name, .text).notNull()
                t.column(WCSessionRecord.Columns.dAppName.name, .text).notNull()
                t.column(WCSessionRecord.Columns.namespaces.name, .blob).notNull()
            }
        }

        return migrator
    }
}

extension WCSessionStorage {
    func sessions() throws -> [WCSessionRecord] {
        try dbPool.read { db in
            try WCSessionRecord.fetchAll(db)
        }
    }

    func sessions(accountId: String) throws -> [WCSessionRecord] {
        try dbPool.read { db in
            try WCSessionRecord.filter(WCSessionRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func session(topic: String) throws -> WCSessionRecord? {
        try dbPool.read { db in
            try WCSessionRecord.filter(WCSessionRecord.Columns.topic == topic).fetchOne(db)
        }
    }

    func save(session: WCSessionRecord) throws {
        _ = try dbPool.write { db in
            try session.insert(db)
        }
    }

    func delete(topics: [String]) throws {
        _ = try dbPool.write { db in
            try WCSessionRecord.filter(topics.contains(WCSessionRecord.Columns.topic)).deleteAll(db)
        }
    }

    func delete(accountId: String) throws {
        _ = try dbPool.write { db in
            try WCSessionRecord.filter(WCSessionRecord.Columns.accountId == accountId).deleteAll(db)
        }
    }
}
