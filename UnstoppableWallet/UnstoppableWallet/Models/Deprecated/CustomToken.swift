import GRDB
import MarketKit

class CustomToken: Record {
    static let uidPrefix = "custom_"

    let coinName: String
    let coinCode: String
    let coinTypeId: String
    let decimals: Int

    override class var databaseTableName: String {
        "custom_tokens"
    }

    enum Columns: String, ColumnExpression {
        case coinName, coinCode, coinTypeId, decimals
    }

    required init(row: Row) {
        coinName = row[Columns.coinName]
        coinCode = row[Columns.coinCode]
        coinTypeId = row[Columns.coinTypeId]
        decimals = row[Columns.decimals]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinName] = coinName
        container[Columns.coinCode] = coinCode
        container[Columns.coinTypeId] = coinTypeId
        container[Columns.decimals] = decimals
    }

}
