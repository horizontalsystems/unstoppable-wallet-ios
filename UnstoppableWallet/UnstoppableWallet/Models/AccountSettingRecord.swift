import GRDB

class AccountSettingRecord: Record {
    let accountId: String
    let key: String
    let value: String

    init(accountId: String, key: String, value: String) {
        self.accountId = accountId
        self.key = key
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "account_settings"
    }

    enum Columns: String, ColumnExpression {
        case accountId, key, value
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        key = row[Columns.key]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.key] = key
        container[Columns.value] = value
    }

}
