import GRDB

class SyncerState: Record {
    let key: String
    let value: String

    enum Columns: String, ColumnExpression, CaseIterable {
        case key, value
    }

    init(key: String, value: String) {
        self.key = key
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "syncerStates"
    }

    required init(row: Row) {
        key = row[Columns.key]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.key] = key
        container[Columns.value] = value
    }

}
