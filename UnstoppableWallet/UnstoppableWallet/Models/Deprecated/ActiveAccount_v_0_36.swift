import GRDB

class ActiveAccount_v_0_36: Record {
    let uniqueId: String = "active_account"
    let accountId: String

    init(accountId: String) {
        self.accountId = accountId

        super.init()
    }

    override class var databaseTableName: String {
        "active_account"
    }

    enum Columns: String, ColumnExpression {
        case uniqueId, accountId
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.uniqueId] = uniqueId
        container[Columns.accountId] = accountId
    }

}
