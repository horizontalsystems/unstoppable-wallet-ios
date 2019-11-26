import GRDB

class AccountRecord_v_0_10: Record {
    let id: String
    let name: String
    let type: String
    let backedUp: Bool
    var defaultSyncMode: String?
    var wordsKey: String?
    var derivation: String?
    var saltKey: String?
    var dataKey: String?
    var eosAccount: String?

    init(id: String, name: String, type: String, backedUp: Bool, defaultSyncMode: String?, wordsKey: String?, derivation: String?, saltKey: String?, dataKey: String?, eosAccount: String?) {
        self.id = id
        self.name = name
        self.type = type
        self.backedUp = backedUp
        self.defaultSyncMode = defaultSyncMode
        self.wordsKey = wordsKey
        self.derivation = derivation
        self.saltKey = saltKey
        self.dataKey = dataKey
        self.eosAccount = eosAccount

        super.init()
    }

    override class var databaseTableName: String {
        "account_records"
    }

    enum Columns: String, ColumnExpression {
        case id, name, type, backedUp, defaultSyncMode
        case wordsKey, derivation, saltKey, dataKey, eosAccount
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        type = row[Columns.type]
        backedUp = row[Columns.backedUp]
        defaultSyncMode = row[Columns.defaultSyncMode]
        wordsKey = row[Columns.wordsKey]
        derivation = row[Columns.derivation]
        saltKey = row[Columns.saltKey]
        dataKey = row[Columns.dataKey]
        eosAccount = row[Columns.eosAccount]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.type] = type
        container[Columns.backedUp] = backedUp
        container[Columns.defaultSyncMode] = defaultSyncMode
        container[Columns.wordsKey] = wordsKey
        container[Columns.derivation] = derivation
        container[Columns.saltKey] = saltKey
        container[Columns.dataKey] = dataKey
        container[Columns.eosAccount] = eosAccount
    }

}
