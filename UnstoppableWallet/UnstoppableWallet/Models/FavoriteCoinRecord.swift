import GRDB

class FavoriteCoinRecord: Record {
    let coinCode: String
    let coinType: String?

    init(coinCode: String, coinType: CoinType?) {
        self.coinCode = coinCode
        self.coinType = coinType?.rawValue

        super.init()
    }


    override class var databaseTableName: String {
        "favorite_coins"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, coinType
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        coinType = row[Columns.coinType]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.coinType] = coinType
    }

}
