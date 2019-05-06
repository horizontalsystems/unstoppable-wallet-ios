import GRDB

class EnabledCoin: Record {
    let coinCode: CoinCode
    let order: Int

    init(coinCode: CoinCode, order: Int) {
        self.coinCode = coinCode
        self.order = order

        super.init()
    }

    enum Columns: String, ColumnExpression {
        case coinCode, coinOrder
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        order = row[Columns.coinOrder]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.coinOrder] = order
    }

    override class var databaseTableName: String {
        return "enabled_coins"
    }

}
