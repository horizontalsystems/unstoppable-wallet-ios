import GRDB

class RestoreSettingRecord_v_0_25: Record {
    let accountId: String
    let coinId: String
    let key: String
    let value: String

    init(accountId: String, coinId: String, key: String, value: String) {
        self.accountId = accountId
        self.coinId = coinId
        self.key = key
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "restore_settings"
    }

    enum Columns: String, ColumnExpression {
        case accountId, coinId, key, value
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        coinId = row[Columns.coinId]
        key = row[Columns.key]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.coinId] = coinId
        container[Columns.key] = key
        container[Columns.value] = value
    }

}
