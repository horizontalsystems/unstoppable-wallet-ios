import GRDB

class EvmAccountSyncState: Record {
    let accountId: String
    let chainId: Int
    let lastTransactionBlockNumber: Int?

    init(accountId: String, chainId: Int, lastTransactionBlockNumber: Int?) {
        self.accountId = accountId
        self.chainId = chainId
        self.lastTransactionBlockNumber = lastTransactionBlockNumber

        super.init()
    }

    override class var databaseTableName: String {
        "evmAccountSyncStates"
    }

    enum Columns: String, ColumnExpression {
        case accountId, chainId, lastTransactionBlockNumber
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        chainId = row[Columns.chainId]
        lastTransactionBlockNumber = row[Columns.lastTransactionBlockNumber]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.chainId] = chainId
        container[Columns.lastTransactionBlockNumber] = lastTransactionBlockNumber
    }

}
