import Foundation
import GRDB

class TonConnectStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create tonConnectApp") { db in
            try db.create(table: "tonConnectApp") { t in
                t.column(TonConnectApp.Columns.accountId.name, .text).notNull()
                t.column(TonConnectApp.Columns.clientId.name, .text).notNull()
                t.column(TonConnectApp.Columns.manifest.name, .text).notNull()
                t.column(TonConnectApp.Columns.keyPair.name, .text).notNull()

                t.primaryKey([TonConnectApp.Columns.accountId.name, TonConnectApp.Columns.clientId.name], onConflict: .replace)
            }

            try db.create(table: "tonConnectLastEvent") { t in
                t.primaryKey(TonConnectLastEvent.Columns.uniqueField.name, .text, onConflict: .replace)
                t.column(TonConnectLastEvent.Columns.id.name, .text).notNull()
            }
        }

        return migrator
    }
}

extension TonConnectStorage {
    func tonConnectApps() throws -> [TonConnectApp] {
        try dbPool.read { db in
            try TonConnectApp.fetchAll(db)
        }
    }

    func save(tonConnectApp: TonConnectApp) throws {
        _ = try dbPool.write { db in
            try tonConnectApp.insert(db)
        }
    }

    func delete(tonConnectApp: TonConnectApp) throws {
        _ = try dbPool.write { db in
            try TonConnectApp.filter(TonConnectApp.Columns.accountId == tonConnectApp.accountId && TonConnectApp.Columns.clientId == tonConnectApp.clientId).deleteAll(db)
        }
    }

    func lastEventId() throws -> String? {
        try dbPool.read { db in
            try TonConnectLastEvent.fetchOne(db)?.id
        }
    }

    func save(lastEventId: String) throws {
        _ = try dbPool.write { db in
            try TonConnectLastEvent(id: lastEventId).insert(db)
        }
    }
}
