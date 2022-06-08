import GRDB

class EnabledWallet_v_0_25: Record {
    let coinId: String
    let coinSettingsId: String
    let accountId: String

    let coinName: String?
    let coinCode: String?
    let coinDecimals: Int?

    init(coinId: String, coinSettingsId: String, accountId: String, coinName: String? = nil, coinCode: String? = nil, coinDecimals: Int? = nil) {
        self.coinId = coinId
        self.coinSettingsId = coinSettingsId
        self.accountId = accountId
        self.coinName = coinName
        self.coinCode = coinCode
        self.coinDecimals = coinDecimals

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

    enum Columns: String, ColumnExpression {
        case coinId, coinSettingsId, accountId, coinName, coinCode, coinDecimals
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        coinSettingsId = row[Columns.coinSettingsId]
        accountId = row[Columns.accountId]
        coinName = row[Columns.coinName]
        coinCode = row[Columns.coinCode]
        coinDecimals = row[Columns.coinDecimals]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.coinSettingsId] = coinSettingsId
        container[Columns.accountId] = accountId
        container[Columns.coinName] = coinName
        container[Columns.coinCode] = coinCode
        container[Columns.coinDecimals] = coinDecimals
    }

}
