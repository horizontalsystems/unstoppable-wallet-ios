import GRDB

class ActiveAccount: Record {
    let level: Int
    let accountId: String

    init(level: Int, accountId: String) {
        self.level = level
        self.accountId = accountId

        super.init()
    }

    override class var databaseTableName: String {
        "active_account"
    }

    enum Columns: String, ColumnExpression {
        case level, accountId
    }

    required init(row: Row) {
        level = row[Columns.level]
        accountId = row[Columns.accountId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.level] = level
        container[Columns.accountId] = accountId
    }

}
