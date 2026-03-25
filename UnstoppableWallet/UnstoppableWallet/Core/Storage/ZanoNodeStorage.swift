import GRDB

class ZanoNodeStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension ZanoNodeStorage {
    func records(blockchainTypeUid: String) throws -> [ZanoNodeRecord] {
        try dbPool.read { db in
            try ZanoNodeRecord.filter(ZanoNodeRecord.Columns.blockchainTypeUid == blockchainTypeUid).fetchAll(db)
        }
    }

    func save(record: ZanoNodeRecord) throws {
        _ = try dbPool.write { db in
            try record.save(db)
        }
    }

    func delete(blockchainTypeUid: String, url: String) throws {
        _ = try dbPool.write { db in
            try ZanoNodeRecord.filter(ZanoNodeRecord.Columns.blockchainTypeUid == blockchainTypeUid && ZanoNodeRecord.Columns.url == url).deleteAll(db)
        }
    }
}
