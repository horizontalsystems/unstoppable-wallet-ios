import GRDB

class EnabledWallet_v_0_13: Record {
    let coinId: String
    let accountId: String

    var derivation: String?
    var syncMode: String?

    init(coinId: String, accountId: String, derivation: String?, syncMode: String?) {
        self.coinId = coinId
        self.accountId = accountId

        self.derivation = derivation
        self.syncMode = syncMode

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

    enum Columns: String, ColumnExpression {
        case coinId, accountId, derivation, syncMode
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        accountId = row[Columns.accountId]
        derivation = row[Columns.derivation]
        syncMode = row[Columns.syncMode]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.accountId] = accountId
        container[Columns.derivation] = derivation
        container[Columns.syncMode] = syncMode
    }

}
