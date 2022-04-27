import GRDB

class SyncerStateStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension SyncerStateStorage {

    func value(key: String) throws -> String? {
        try dbPool.read { db in
            try SyncerState.filter(SyncerState.Columns.key == key).fetchOne(db)?.value
        }
    }

    func save(value: String, key: String) throws {
        _ = try dbPool.write { db in
            let syncerState = SyncerState(key: key, value: value)
            try syncerState.insert(db)
        }
    }

    func delete(key: String) throws {
        _ = try dbPool.write { db in
            try SyncerState.filter(SyncerState.Columns.key == key).deleteAll(db)
        }
    }

}
