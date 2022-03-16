import GRDB

class WalletConnectV2SessionStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension WalletConnectV2SessionStorage {

    func sessionsV2(accountId: String?) -> [WalletConnectV2Session] {
        try! dbPool.read { db in
            var request = WalletConnectV2Session.all()
            if let accountId = accountId {
                request = request.filter(WalletConnectV2Session.Columns.accountId == accountId)
            }
            return try request.fetchAll(db)
        }
    }

    func save(sessions: [WalletConnectV2Session]) {
        _ = try! dbPool.write { db in
            for session in sessions {
                try session.insert(db)
            }
        }
    }

    func deleteSessionV2(topics: [String]) {
        _ = try! dbPool.write { db in
            for topic in topics {
                try WalletConnectV2Session.filter(WalletConnectV2Session.Columns.topic == topic).deleteAll(db)
            }
        }
    }

    func deleteSessionsV2(accountId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectV2Session.filter(WalletConnectV2Session.Columns.accountId == accountId).deleteAll(db)
        }
    }

}
