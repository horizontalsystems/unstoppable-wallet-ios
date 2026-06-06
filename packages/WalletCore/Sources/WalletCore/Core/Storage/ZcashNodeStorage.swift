import GRDB

class ZcashNodeStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension ZcashNodeStorage {
    func getAll() throws -> [ZcashNodeRecord] {
        try dbPool.read { db in
            try ZcashNodeRecord.fetchAll(db)
        }
    }

    func records(blockchainTypeUid: String) throws -> [ZcashNodeRecord] {
        try dbPool.read { db in
            try ZcashNodeRecord.filter(ZcashNodeRecord.Columns.blockchainTypeUid == blockchainTypeUid).fetchAll(db)
        }
    }

    func save(record: ZcashNodeRecord) throws {
        _ = try dbPool.write { db in
            try record.save(db)
        }
    }

    func delete(blockchainTypeUid: String, url: String) throws {
        _ = try dbPool.write { db in
            try ZcashNodeRecord.filter(ZcashNodeRecord.Columns.blockchainTypeUid == blockchainTypeUid && ZcashNodeRecord.Columns.url == url).deleteAll(db)
        }
    }
}
