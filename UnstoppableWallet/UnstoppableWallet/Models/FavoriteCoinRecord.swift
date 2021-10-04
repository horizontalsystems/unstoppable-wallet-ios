import GRDB

class FavoriteCoinRecord: Record {
    let coinUid: String

    init(coinUid: String) {
        self.coinUid = coinUid

        super.init()
    }


    override class var databaseTableName: String {
        "favorite_coins"
    }

    enum Columns: String, ColumnExpression {
        case coinUid
    }

    required init(row: Row) {
        coinUid = row[Columns.coinUid]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinUid] = coinUid
    }

}
