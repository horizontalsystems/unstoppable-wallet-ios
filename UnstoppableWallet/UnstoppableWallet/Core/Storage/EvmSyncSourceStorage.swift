import GRDB

class EvmSyncSourceStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension EvmSyncSourceStorage {

    func getAll() throws ->  [EvmSyncSourceRecord] {
        try dbPool.read { db in
            try EvmSyncSourceRecord.fetchAll(db)
        }
    }

    func records(blockchainTypeUid: String) throws -> [EvmSyncSourceRecord] {
        try dbPool.read { db in
            try EvmSyncSourceRecord.filter(EvmSyncSourceRecord.Columns.blockchainTypeUid == blockchainTypeUid).fetchAll(db)
        }
    }

    func save(record: EvmSyncSourceRecord) throws {
        _ = try dbPool.write { db in
            try record.insert(db)
        }

    }

    func delete(blockchainTypeUid: String, url: String) throws {
        _ = try dbPool.write { db in
            try EvmSyncSourceRecord.filter(EvmSyncSourceRecord.Columns.blockchainTypeUid == blockchainTypeUid && EvmSyncSourceRecord.Columns.url == url).deleteAll(db)
        }
    }

}
