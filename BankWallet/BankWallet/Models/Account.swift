import GRDB

class Account: Record {
    let id: String
    let name: String
    let type: AccountType
    var backedUp: Bool
    var defaultSyncMode: SyncMode?

    init(id: String, name: String, type: AccountType, backedUp: Bool, defaultSyncMode: SyncMode?) {
        self.id = id
        self.name = name
        self.type = type
        self.backedUp = backedUp
        self.defaultSyncMode = defaultSyncMode

        super.init()
    }

    override class var databaseTableName: String {
        return "account"
    }

    enum Columns: String, ColumnExpression {
        case id, name, type, backedUp, defaultSyncMode
        case words, derivation, salt, data, eosAccount
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        let typeName: TypeNames = row[Columns.type]
        switch typeName {
        case .mnemonic:
            let words: EncryptedStringArray = row[Columns.words]
            let derivation: MnemonicDerivation = row[Columns.derivation]
            let salt: EncryptedString? = row[Columns.salt]
            type = .mnemonic(words: words.array, derivation: derivation, salt: salt?.string)
        case .privateKey:
            let data: EncryptedData = row[Columns.data]
            type = .privateKey(data: data.data)
        case .hdMasterKey:
            let data: EncryptedData = row[Columns.data]
            let derivation: MnemonicDerivation = row[Columns.derivation]
            type = .hdMasterKey(data: data.data, derivation: derivation)
        case .eos:
            let account: EncryptedString = row[Columns.eosAccount]
            let data: EncryptedData = row[Columns.data]
            type = .eos(account: account.string, activePrivateKey: data.data)
        }
        backedUp = row[Columns.backedUp]
        defaultSyncMode = row[Columns.defaultSyncMode]
        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        switch type {
        case .mnemonic(let words, let derivation, let salt):
            container[Columns.type] = TypeNames.mnemonic
            container[Columns.words] = EncryptedStringArray(array: words)
            container[Columns.derivation] = derivation
            container[Columns.salt] = EncryptedString(string: salt)
        case .privateKey(let data):
            container[Columns.type] = TypeNames.privateKey
            container[Columns.data] = EncryptedData(data: data)
        case .hdMasterKey(let data, let derivation):
            container[Columns.type] = TypeNames.hdMasterKey
            container[Columns.data] = EncryptedData(data: data)
            container[Columns.derivation] = derivation
        case .eos(let account, let activePrivateKey):
            container[Columns.type] = TypeNames.eos
            container[Columns.eosAccount] = EncryptedString(string: account)
            container[Columns.data] = EncryptedData(data: activePrivateKey)
        }
        container[Columns.backedUp] = backedUp
        container[Columns.defaultSyncMode] = defaultSyncMode
    }

}

extension Account: Equatable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }

}
