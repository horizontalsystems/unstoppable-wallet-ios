import GRDB
import MarketKit

class EnabledWallet: Record {
    let tokenQueryId: String
    let accountId: String

    let coinName: String?
    let coinCode: String?
    let tokenDecimals: Int?

    init(tokenQueryId: String, accountId: String, coinName: String? = nil, coinCode: String? = nil, tokenDecimals: Int? = nil) {
        self.tokenQueryId = tokenQueryId
        self.accountId = accountId
        self.coinName = coinName
        self.coinCode = coinCode
        self.tokenDecimals = tokenDecimals

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

    enum Columns: String, ColumnExpression {
        case tokenQueryId, accountId, coinName, coinCode, tokenDecimals
    }

    required init(row: Row) throws {
        tokenQueryId = row[Columns.tokenQueryId]
        accountId = row[Columns.accountId]
        coinName = row[Columns.coinName]
        coinCode = row[Columns.coinCode]
        tokenDecimals = row[Columns.tokenDecimals]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.tokenQueryId] = tokenQueryId
        container[Columns.accountId] = accountId
        container[Columns.coinName] = coinName
        container[Columns.coinCode] = coinCode
        container[Columns.tokenDecimals] = tokenDecimals
    }

}
