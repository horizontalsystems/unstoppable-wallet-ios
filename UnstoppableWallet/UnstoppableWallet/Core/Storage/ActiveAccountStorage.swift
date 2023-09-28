import GRDB

class ActiveAccountStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension ActiveAccountStorage {

    func activeAccountId(level: Int) -> String? {
        try? dbPool.read { db in
            try ActiveAccount.filter(ActiveAccount.Columns.level == level).fetchOne(db)?.accountId
        }
    }

    func save(activeAccountId: String?, level: Int) {
        _ = try? dbPool.write { db in
            if let activeAccountId {
                try ActiveAccount(level: level, accountId: activeAccountId).insert(db)
            } else {
                try ActiveAccount.filter(ActiveAccount.Columns.level == level).deleteAll(db)
            }
        }
    }

}
