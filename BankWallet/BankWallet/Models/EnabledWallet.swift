import GRDB

class EnabledWallet: Record {
    let coinCode: CoinCode
    let accountId: String
    var syncMode: SyncMode?
    let order: Int

    init(coinCode: CoinCode, accountId: String, syncMode: SyncMode?, order: Int) {
        self.coinCode = coinCode
        self.accountId = accountId
        self.syncMode = syncMode
        self.order = order

        super.init()
    }

    enum Columns: String, ColumnExpression {
        case coinCode, accountId, syncMode, walletOrder
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        accountId = row[Columns.accountId]
        order = row[Columns.walletOrder]

        if let rawSyncMode: String = row[Columns.syncMode] {
            syncMode = SyncMode(rawValue: rawSyncMode)
        }

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.accountId] = accountId
        container[Columns.syncMode] = syncMode?.rawValue
        container[Columns.walletOrder] = order
    }

    override class var databaseTableName: String {
        return "enabled_wallets"
    }

}
