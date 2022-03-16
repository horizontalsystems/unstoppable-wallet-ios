import GRDB

class EvmAccountSyncStateStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension EvmAccountSyncStateStorage {

    func evmAccountSyncState(accountId: String, chainId: Int) -> EvmAccountSyncState? {
        try! dbPool.read { db in
            try EvmAccountSyncState.filter(EvmAccountSyncState.Columns.accountId == accountId && EvmAccountSyncState.Columns.chainId == chainId).fetchOne(db)
        }
    }

    func save(evmAccountSyncState: EvmAccountSyncState) {
        _ = try! dbPool.write { db in
            try evmAccountSyncState.insert(db)
        }
    }

}
