import GRDB

public class ActiveAccount: Record {
    public let level: Int
    public let accountId: String

    public init(level: Int, accountId: String) {
        self.level = level
        self.accountId = accountId

        super.init()
    }

    override public class var databaseTableName: String {
        "active_account"
    }

    public enum Columns: String, ColumnExpression {
        case level, accountId
    }

    public required init(row: Row) throws {
        level = row[Columns.level]
        accountId = row[Columns.accountId]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.level] = level
        container[Columns.accountId] = accountId
    }
}
