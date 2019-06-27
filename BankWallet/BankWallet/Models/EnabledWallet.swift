import GRDB

class EnabledWallet: Record {
    let coinCode: CoinCode
    let accountName: String
    let order: Int

    init(coinCode: CoinCode, accountName: String, order: Int) {
        self.coinCode = coinCode
        self.accountName = accountName
        self.order = order

        super.init()
    }

    enum Columns: String, ColumnExpression {
        case coinCode, accountName, walletOrder
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        accountName = row[Columns.accountName]
        order = row[Columns.walletOrder]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.accountName] = accountName
        container[Columns.walletOrder] = order
    }

    override class var databaseTableName: String {
        return "enabled_wallets"
    }

}
