import GRDB

class MoneroNodeStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension MoneroNodeStorage {
    func getAll() throws -> [MoneroNodeRecord] {
        try dbPool.read { db in
            try MoneroNodeRecord.fetchAll(db)
        }
    }

    func records(blockchainTypeUid: String) throws -> [MoneroNodeRecord] {
        try dbPool.read { db in
            try MoneroNodeRecord.filter(MoneroNodeRecord.Columns.blockchainTypeUid == blockchainTypeUid).fetchAll(db)
        }
    }

    func save(record: MoneroNodeRecord) throws {
        _ = try dbPool.write { db in
            try record.save(db)
        }
    }

    func delete(blockchainTypeUid: String, url: String) throws {
        _ = try dbPool.write { db in
            try MoneroNodeRecord.filter(MoneroNodeRecord.Columns.blockchainTypeUid == blockchainTypeUid && MoneroNodeRecord.Columns.url == url).deleteAll(db)
        }
    }
}
