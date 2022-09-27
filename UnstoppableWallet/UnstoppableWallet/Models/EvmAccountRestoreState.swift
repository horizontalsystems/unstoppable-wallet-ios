import GRDB

class EvmAccountRestoreState: Record {
    let accountId: String
    let blockchainUid: String
    let restored: Bool

    init(accountId: String, blockchainUid: String, restored: Bool) {
        self.accountId = accountId
        self.blockchainUid = blockchainUid
        self.restored = restored

        super.init()
    }

    override class var databaseTableName: String {
        "evmAccountRestoreStates"
    }

    enum Columns: String, ColumnExpression {
        case accountId, blockchainUid, restored
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        blockchainUid = row[Columns.blockchainUid]
        restored = row[Columns.restored]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.blockchainUid] = blockchainUid
        container[Columns.restored] = restored
    }

}
