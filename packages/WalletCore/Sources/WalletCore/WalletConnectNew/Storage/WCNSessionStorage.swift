import GRDB

class WCNSessionStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create wcnSession") { db in
            try db.create(table: WCNSessionRecord.databaseTableName) { t in
                t.primaryKey(WCNSessionRecord.Columns.topic.name, .text, onConflict: .replace)
                t.column(WCNSessionRecord.Columns.accountId.name, .text).notNull()
                t.column(WCNSessionRecord.Columns.dAppName.name, .text).notNull()
                t.column(WCNSessionRecord.Columns.namespaces.name, .blob).notNull()
            }
        }

        return migrator
    }
}

extension WCNSessionStorage {
    func sessions() throws -> [WCNSessionRecord] {
        try dbPool.read { db in
            try WCNSessionRecord.fetchAll(db)
        }
    }

    func sessions(accountId: String) throws -> [WCNSessionRecord] {
        try dbPool.read { db in
            try WCNSessionRecord.filter(WCNSessionRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func session(topic: String) throws -> WCNSessionRecord? {
        try dbPool.read { db in
            try WCNSessionRecord.filter(WCNSessionRecord.Columns.topic == topic).fetchOne(db)
        }
    }

    func save(session: WCNSessionRecord) throws {
        _ = try dbPool.write { db in
            try session.insert(db)
        }
    }

    func delete(topics: [String]) throws {
        _ = try dbPool.write { db in
            try WCNSessionRecord.filter(topics.contains(WCNSessionRecord.Columns.topic)).deleteAll(db)
        }
    }

    func delete(accountId: String) throws {
        _ = try dbPool.write { db in
            try WCNSessionRecord.filter(WCNSessionRecord.Columns.accountId == accountId).deleteAll(db)
        }
    }
}
