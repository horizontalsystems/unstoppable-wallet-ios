import GRDB

class EnabledWalletNew: Record {
    let coinUid: String
    let coinTypeId: String
    let coinSettingsId: String
    let accountId: String

    init(coinUid: String, coinTypeId: String, coinSettingsId: String, accountId: String) {
        self.coinUid = coinUid
        self.coinTypeId = coinTypeId
        self.coinSettingsId = coinSettingsId
        self.accountId = accountId

        super.init()
    }

    override class var databaseTableName: String {
        "enabled_wallets_new"
    }

    enum Columns: String, ColumnExpression {
        case coinUid, coinTypeId, coinSettingsId, accountId
    }

    required init(row: Row) {
        coinUid = row[Columns.coinUid]
        coinTypeId = row[Columns.coinTypeId]
        coinSettingsId = row[Columns.coinSettingsId]
        accountId = row[Columns.accountId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinUid] = coinUid
        container[Columns.coinTypeId] = coinTypeId
        container[Columns.coinSettingsId] = coinSettingsId
        container[Columns.accountId] = accountId
    }

}
