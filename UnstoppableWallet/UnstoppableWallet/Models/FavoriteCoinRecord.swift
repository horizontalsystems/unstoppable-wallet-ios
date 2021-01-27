import GRDB

class FavoriteCoinRecord: Record {
    let coinCode: String

    init(coinCode: String) {
        self.coinCode = coinCode

        super.init()
    }


    override class var databaseTableName: String {
        "favorite_coins"
    }

    enum Columns: String, ColumnExpression {
        case coinCode
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
    }

}
