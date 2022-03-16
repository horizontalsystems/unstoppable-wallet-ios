import GRDB

class AccountRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension AccountRecordStorage {

    var all: [AccountRecord] {
        try! dbPool.read { db in
            try AccountRecord.fetchAll(db)
        }
    }

    func save(record: AccountRecord) {
        _ = try! dbPool.write { db in
            try record.insert(db)
        }
    }

    func delete(by id: String) {
        _ = try! dbPool.write { db in
            try AccountRecord.filter(AccountRecord.Columns.id == id).deleteAll(db)
        }
    }

    func clear() {
        _ = try! dbPool.write { db in
            try AccountRecord.deleteAll(db)
        }
    }

}
