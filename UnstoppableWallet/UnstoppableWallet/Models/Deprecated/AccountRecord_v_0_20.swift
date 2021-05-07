import GRDB

class AccountRecord_v_0_20: Record {
    let id: String
    let name: String
    let type: String
    let origin: String
    let backedUp: Bool
    var wordsKey: String?
    var saltKey: String?
    var birthdayHeightKey: String?
    var dataKey: String?

    init(id: String, name: String, type: String, origin: String, backedUp: Bool, wordsKey: String?, saltKey: String?, birthdayHeightKey: String?, dataKey: String?) {
        self.id = id
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
        self.wordsKey = wordsKey
        self.saltKey = saltKey
        self.birthdayHeightKey = birthdayHeightKey
        self.dataKey = dataKey

        super.init()
    }

    override class var databaseTableName: String {
        "account_records"
    }

    enum Columns: String, ColumnExpression {
        case id, name, type, origin, backedUp, wordsKey, saltKey, birthdayHeightKey, dataKey
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        type = row[Columns.type]
        origin = row[Columns.origin]
        backedUp = row[Columns.backedUp]
        wordsKey = row[Columns.wordsKey]
        saltKey = row[Columns.saltKey]
        birthdayHeightKey = row[Columns.birthdayHeightKey]
        dataKey = row[Columns.dataKey]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.type] = type
        container[Columns.origin] = origin
        container[Columns.backedUp] = backedUp
        container[Columns.wordsKey] = wordsKey
        container[Columns.saltKey] = saltKey
        container[Columns.birthdayHeightKey] = birthdayHeightKey
        container[Columns.dataKey] = dataKey
    }

}
