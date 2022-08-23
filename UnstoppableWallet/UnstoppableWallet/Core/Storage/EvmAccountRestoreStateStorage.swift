import GRDB

class EvmAccountRestoreStateStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension EvmAccountRestoreStateStorage {

    func evmAccountRestoreState(accountId: String, blockchainUid: String) throws -> EvmAccountRestoreState? {
        try dbPool.read { db in
            try EvmAccountRestoreState.filter(EvmAccountRestoreState.Columns.accountId == accountId && EvmAccountRestoreState.Columns.blockchainUid == blockchainUid).fetchOne(db)
        }
    }

    func save(evmAccountRestoreState: EvmAccountRestoreState) throws {
        _ = try dbPool.write { db in
            try evmAccountRestoreState.insert(db)
        }
    }

}
