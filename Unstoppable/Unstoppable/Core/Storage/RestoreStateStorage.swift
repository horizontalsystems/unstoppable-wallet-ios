import GRDB

class RestoreStateStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension RestoreStateStorage {
    func restoreState(accountId: String, blockchainUid: String) throws -> RestoreState? {
        try dbPool.read { db in
            try RestoreState.filter(RestoreState.Columns.accountId == accountId && RestoreState.Columns.blockchainUid == blockchainUid).fetchOne(db)
        }
    }

    func save(restoreState: RestoreState) throws {
        _ = try dbPool.write { db in
            try restoreState.insert(db)
        }
    }
}
