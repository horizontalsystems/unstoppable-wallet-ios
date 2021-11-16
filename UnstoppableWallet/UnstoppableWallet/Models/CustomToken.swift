import GRDB
import MarketKit

class CustomToken: Record {
    static let uidPrefix = "custom_"

    let coinName: String
    let coinCode: String
    let coinType: CoinType
    let decimals: Int

    init(coinName: String, coinCode: String, coinType: CoinType, decimals: Int) {
        self.coinName = coinName
        self.coinCode = coinCode
        self.coinType = coinType
        self.decimals = decimals

        super.init()
    }

    var platformCoin: PlatformCoin {
        let coinUid = "\(Self.uidPrefix)\(coinName)_\(coinCode)"

        return PlatformCoin(
                coin: Coin(uid: coinUid, name: coinName, code: coinCode),
                platform: Platform(coinType: coinType, decimals: decimals, coinUid: coinUid)
        )
    }

    override class var databaseTableName: String {
        "custom_tokens"
    }

    enum Columns: String, ColumnExpression {
        case coinName, coinCode, coinTypeId, decimals
    }

    required init(row: Row) {
        coinName = row[Columns.coinName]
        coinCode = row[Columns.coinCode]
        coinType = CoinType(id: row[Columns.coinTypeId])
        decimals = row[Columns.decimals]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinName] = coinName
        container[Columns.coinCode] = coinCode
        container[Columns.coinTypeId] = coinType.id
        container[Columns.decimals] = decimals
    }

}
