import GRDB
import MarketKit

class CustomToken: Record {
    let coinName: String
    let coinCode: String
    let coinType: CoinType
    let decimal: Int

    init(coinName: String, coinCode: String, coinType: CoinType, decimal: Int) {
        self.coinName = coinName
        self.coinCode = coinCode
        self.coinType = coinType
        self.decimal = decimal

        super.init()
    }

    var platformCoin: PlatformCoin {
        let coinUid = "custom_\(coinName)_\(coinCode)"

        return PlatformCoin(
                coin: Coin(uid: coinUid, name: coinName, code: coinCode),
                platform: Platform(coinType: coinType, decimal: decimal, coinUid: coinUid)
        )
    }

    override class var databaseTableName: String {
        "custom_tokens"
    }

    enum Columns: String, ColumnExpression {
        case coinName, coinCode, coinTypeId, decimal
    }

    required init(row: Row) {
        coinName = row[Columns.coinName]
        coinCode = row[Columns.coinCode]
        coinType = CoinType(id: row[Columns.coinTypeId])
        decimal = row[Columns.decimal]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinName] = coinName
        container[Columns.coinCode] = coinCode
        container[Columns.coinTypeId] = coinType.id
        container[Columns.decimal] = decimal
    }

}
