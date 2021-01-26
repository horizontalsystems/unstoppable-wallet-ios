import GRDB

class FavoriteCoinRecord: Record {
    let coinCode: String
    let coinTitle: String
    let coinType: String?

    init(coinCode: String, coinTitle: String, coinType: CoinType?) {
        self.coinCode = coinCode
        self.coinTitle = coinTitle
        self.coinType = coinType?.rawValue

        super.init()
    }


    override class var databaseTableName: String {
        "favorite_coins"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, coinTitle, coinType
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        coinTitle = row[Columns.coinTitle]
        coinType = row[Columns.coinType]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.coinTitle] = coinTitle
        container[Columns.coinType] = coinType
    }

}
