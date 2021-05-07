import GRDB

class EnabledWallet: Record {
    let coinId: String
    let coinSettingsId: String
    let accountId: String

    init(coinId: String, coinSettingsId: String, accountId: String) {
        self.coinId = coinId
        self.coinSettingsId = coinSettingsId
        self.accountId = accountId

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets"
    }

    enum Columns: String, ColumnExpression {
        case coinId, coinSettingsId, accountId
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        coinSettingsId = row[Columns.coinSettingsId]
        accountId = row[Columns.accountId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.coinSettingsId] = coinSettingsId
        container[Columns.accountId] = accountId
    }

}
