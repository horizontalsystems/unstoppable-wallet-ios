import GRDB

class AccountRecord: Record {
    let id: String
    let name: String
    let type: String
    let origin: String
    let backedUp: Bool
    var wordsKey: String?
    var saltKey: String?
    var dataKey: String?
    var bip39Compliant: Bool?

    init(id: String, name: String, type: String, origin: String, backedUp: Bool, wordsKey: String?, saltKey: String?, dataKey: String?, bip39Compliant: Bool?) {
        self.id = id
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
        self.wordsKey = wordsKey
        self.saltKey = saltKey
        self.dataKey = dataKey
        self.bip39Compliant = bip39Compliant

        super.init()
    }

    override class var databaseTableName: String {
        "account_records"
    }

    enum Columns: String, ColumnExpression {
        case id, name, type, origin, backedUp, wordsKey, saltKey, dataKey, bip39Compliant
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        type = row[Columns.type]
        origin = row[Columns.origin]
        backedUp = row[Columns.backedUp]
        wordsKey = row[Columns.wordsKey]
        saltKey = row[Columns.saltKey]
        dataKey = row[Columns.dataKey]
        bip39Compliant = row[Columns.bip39Compliant]

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
        container[Columns.dataKey] = dataKey
        container[Columns.bip39Compliant] = bip39Compliant
    }

}
