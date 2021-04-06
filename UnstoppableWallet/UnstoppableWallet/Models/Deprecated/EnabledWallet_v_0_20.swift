import GRDB

class EnabledWallet_v_0_20: Record {
    let coinId: String
    let accountId: String

    init(coinId: String, accountId: String) {
        self.coinId = coinId
        self.accountId = accountId

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

    enum Columns: String, ColumnExpression {
        case coinId, accountId
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        accountId = row[Columns.accountId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.accountId] = accountId
    }

}
