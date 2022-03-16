import GRDB

class EnabledWalletStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension EnabledWalletStorage {

    var enabledWallets: [EnabledWallet] {
        try! dbPool.read { db in
            try EnabledWallet.fetchAll(db)
        }
    }

    func enabledWallets(accountId: String) -> [EnabledWallet] {
        try! dbPool.read { db in
            try EnabledWallet.filter(EnabledWallet.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func handle(newEnabledWallets: [EnabledWallet], deletedEnabledWallets: [EnabledWallet]) {
        _ = try! dbPool.write { db in
            for enabledWallet in newEnabledWallets {
                try enabledWallet.insert(db)
            }
            for enabledWallet in deletedEnabledWallets {
                try EnabledWallet.filter(EnabledWallet.Columns.coinId == enabledWallet.coinId && EnabledWallet.Columns.coinSettingsId == enabledWallet.coinSettingsId && EnabledWallet.Columns.accountId == enabledWallet.accountId).deleteAll(db)
            }
        }

    }

    func clear() {
        _ = try! dbPool.write { db in
            try EnabledWallet.deleteAll(db)
        }
    }

}
