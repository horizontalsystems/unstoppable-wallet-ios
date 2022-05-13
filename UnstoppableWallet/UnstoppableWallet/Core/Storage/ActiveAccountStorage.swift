import GRDB

class ActiveAccountStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension ActiveAccountStorage {

    var activeAccountId: String? {
        get {
            try! dbPool.read { db in
                try ActiveAccount.fetchOne(db)?.accountId
            }
        }
        set {
            _ = try! dbPool.write { db in
                if let accountId = newValue {
                    try ActiveAccount(accountId: accountId).insert(db)
                } else {
                    try ActiveAccount.deleteAll(db)
                }
            }
        }
    }

}
