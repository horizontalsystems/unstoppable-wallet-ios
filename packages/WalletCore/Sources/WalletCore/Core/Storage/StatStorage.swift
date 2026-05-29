import GRDB

class StatStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension StatStorage {
    func all() throws -> [StatRecord] {
        try dbPool.read { db in
            try StatRecord.fetchAll(db)
        }
    }

    func save(record: StatRecord) throws {
        _ = try dbPool.write { db in
            try record.insert(db)
        }
    }

    func clear() throws {
        _ = try dbPool.write { db in
            try StatRecord.deleteAll(db)
        }
    }
}
