import GRDB

class WalletConnectSessionStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension WalletConnectSessionStorage {

    func sessions(accountId: String) -> [WalletConnectSession] {
        try! dbPool.read { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func session(peerId: String, accountId: String) -> WalletConnectSession? {
        try! dbPool.read { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.peerId == peerId && WalletConnectSession.Columns.accountId == accountId).fetchOne(db)
        }
    }

    func save(session: WalletConnectSession) {
        _ = try! dbPool.write { db in
            try session.insert(db)
        }
    }

    func deleteSession(peerId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.peerId == peerId).deleteAll(db)
        }
    }

    func deleteSessions(accountId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.accountId == accountId).deleteAll(db)
        }
    }

}
