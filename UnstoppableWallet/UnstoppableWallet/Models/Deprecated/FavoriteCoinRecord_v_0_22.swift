//import GRDB
//import MarketKit
//
//class FavoriteCoinRecord_v_0_22: Record {
//    let coinType: CoinType
//
//    init(coinType: CoinType) {
//        self.coinType = coinType
//
//        super.init()
//    }
//
//
//    override class var databaseTableName: String {
//        "favorite_coins_v20"
//    }
//
//    enum Columns: String, ColumnExpression {
//        case coinType
//    }
//
//    required init(row: Row) {
//        coinType = CoinType(id: row[Columns.coinType])
//
//        super.init(row: row)
//    }
//
//    override func encode(to container: inout PersistenceContainer) {
//        container[Columns.coinType] = coinType.id
//    }
//
//}
