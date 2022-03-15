import GRDB

class EnabledWallet_v_0_10: Record {
    let coinId: String
    let accountId: String
    var syncMode: SyncMode_v_0_24?
    let order: Int

    init(coinId: String, accountId: String, syncMode: SyncMode_v_0_24?, order: Int) {
        self.coinId = coinId
        self.accountId = accountId
        self.syncMode = syncMode
        self.order = order

        super.init()
    }

    enum Columns: String, ColumnExpression {
        case coinId, accountId, syncMode, walletOrder
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        accountId = row[Columns.accountId]
        order = row[Columns.walletOrder]

        if let rawSyncMode: String = row[Columns.syncMode] {
            syncMode = SyncMode_v_0_24(rawValue: rawSyncMode)
        }

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.accountId] = accountId
        container[Columns.syncMode] = syncMode?.rawValue
        container[Columns.walletOrder] = order
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

}
