import GRDB

class EnabledWalletCacheStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension EnabledWalletCacheStorage {

    func enabledWalletCaches(accountId: String) -> [EnabledWalletCache] {
        try! dbPool.read { db in
            try EnabledWalletCache.filter(EnabledWalletCache.Columns.accountId == accountId).fetchAll(db)
        }

    }

    func save(enabledWalletCaches: [EnabledWalletCache]) {
        _ = try! dbPool.write { db in
            for cache in enabledWalletCaches {
                try cache.insert(db)
            }
        }
    }

    func deleteEnabledWalletCaches(accountId: String) {
        _ = try! dbPool.write { db in
            try EnabledWalletCache.filter(EnabledWalletCache.Columns.accountId == accountId).deleteAll(db)
        }
    }

}
