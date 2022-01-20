import GRDB

class EvmAccountSyncState: Record {
    let accountId: String
    let chainId: Int
    let lastBlockNumber: Int

    init(accountId: String, chainId: Int, lastBlockNumber: Int) {
        self.accountId = accountId
        self.chainId = chainId
        self.lastBlockNumber = lastBlockNumber

        super.init()
    }

    override class var databaseTableName: String {
        "evmAccountSyncStates"
    }

    enum Columns: String, ColumnExpression {
        case accountId, chainId, lastBlockNumber
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        chainId = row[Columns.chainId]
        lastBlockNumber = row[Columns.lastBlockNumber]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.chainId] = chainId
        container[Columns.lastBlockNumber] = lastBlockNumber
    }

}
