import GRDB

class WalletConnectSessionStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension WalletConnectSessionStorage {

    func sessions(accountId: String?) -> [WalletConnectSession] {
        try! dbPool.read { db in
            var request = WalletConnectSession.all()
            if let accountId = accountId {
                request = request.filter(WalletConnectSession.Columns.accountId == accountId)
            }
            return try request.fetchAll(db)
        }
    }

    func save(sessions: [WalletConnectSession]) {
        _ = try! dbPool.write { db in
            for session in sessions {
                try session.insert(db)
            }
        }
    }

    func deleteSession(topics: [String]) {
        _ = try! dbPool.write { db in
            for topic in topics {
                try WalletConnectSession.filter(WalletConnectSession.Columns.topic == topic).deleteAll(db)
            }
        }
    }

    func deleteSessions(accountId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.accountId == accountId).deleteAll(db)
        }
    }

}
