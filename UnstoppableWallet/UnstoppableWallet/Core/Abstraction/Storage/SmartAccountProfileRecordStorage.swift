import GRDB

class SmartAccountProfileRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension SmartAccountProfileRecordStorage {
    func all() throws -> [SmartAccountProfileRecord] {
        try dbPool.read { db in
            try SmartAccountProfileRecord.fetchAll(db)
        }
    }

    func profile(id: String) throws -> SmartAccountProfileRecord? {
        try dbPool.read { db in
            try SmartAccountProfileRecord
                .filter(SmartAccountProfileRecord.Columns.id == id)
                .fetchOne(db)
        }
    }

    func profile(accountId: String) throws -> SmartAccountProfileRecord? {
        try dbPool.read { db in
            try SmartAccountProfileRecord
                .filter(SmartAccountProfileRecord.Columns.accountId == accountId)
                .fetchOne(db)
        }
    }

    func save(record: SmartAccountProfileRecord) throws {
        try dbPool.write { db in
            try record.insert(db)
        }
    }

    func delete(id: String) throws {
        try dbPool.write { db in
            try SmartAccountProfileRecord
                .filter(SmartAccountProfileRecord.Columns.id == id)
                .deleteAll(db)
        }
    }

    func delete(accountId: String) throws {
        try dbPool.write { db in
            try SmartAccountProfileRecord
                .filter(SmartAccountProfileRecord.Columns.accountId == accountId)
                .deleteAll(db)
        }
    }

    func clear() throws {
        try dbPool.write { db in
            try SmartAccountProfileRecord.deleteAll(db)
        }
    }
}
