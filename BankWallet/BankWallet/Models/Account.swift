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

    enum TypeNames: Int, DatabaseValueConvertible {
        case mnemonic
        case privateKey
        case hdMasterKey
        case eos

        public var databaseValue: DatabaseValue {
            return rawValue.databaseValue
        }

        public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> TypeNames? {
            guard case .int64(let rawValue) = dbValue.storage else {
                return nil
            }
            return TypeNames(rawValue: Int(rawValue))
        }

        public func keyDBKeychain(id: String, fieldName: String) -> String {
            return "\(rawValue)_\(id)_\(fieldName)"
        }

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
            let words: KeychainStringArray = row[Columns.words]
            let derivation: MnemonicDerivation = row[Columns.derivation]
            let salt: KeychainString? = row[Columns.salt]
            type = .mnemonic(words: words.array, derivation: derivation, salt: salt?.string)
        case .privateKey:
            let data: KeychainData = row[Columns.data]
            type = .privateKey(data: data.data)
        case .hdMasterKey:
            let data: KeychainData = row[Columns.data]
            let derivation: MnemonicDerivation = row[Columns.derivation]
            type = .hdMasterKey(data: data.data, derivation: derivation)
        case .eos:
            let eosAccount: KeychainString = row[Columns.eosAccount]
            let data: KeychainData = row[Columns.data]
            type = .eos(account: eosAccount.string, activePrivateKey: data.data)
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
            container[Columns.words] = KeychainStringArray(array: words, key: TypeNames.mnemonic.keyDBKeychain(id: id, fieldName: "words"))
            container[Columns.derivation] = derivation
            container[Columns.salt] = KeychainString(string: salt, key: TypeNames.mnemonic.keyDBKeychain(id: id, fieldName: "salt"))
        case .privateKey(let data):
            container[Columns.type] = TypeNames.privateKey
            container[Columns.data] = KeychainData(data: data, key: TypeNames.privateKey.keyDBKeychain(id: id, fieldName: "data"))
        case .hdMasterKey(let data, let derivation):
            container[Columns.type] = TypeNames.hdMasterKey
            container[Columns.data] = KeychainData(data: data, key: TypeNames.hdMasterKey.keyDBKeychain(id: id, fieldName: "data"))
            container[Columns.derivation] = derivation
        case .eos(let account, let activePrivateKey):
            container[Columns.type] = TypeNames.eos
            container[Columns.eosAccount] = KeychainString(string: account, key: TypeNames.eos.keyDBKeychain(id: id, fieldName: "eosAccount"))
            container[Columns.data] = KeychainData(data: activePrivateKey, key: TypeNames.eos.keyDBKeychain(id: id, fieldName: "data"))
        }
        container[Columns.backedUp] = backedUp
        container[Columns.defaultSyncMode] = defaultSyncMode
    }

    func clearKeychain() {
        var keys = [String]()
        switch type {
        case .mnemonic(_, _, _):
            keys.append(TypeNames.mnemonic.keyDBKeychain(id: id, fieldName: "words"))
            keys.append(TypeNames.mnemonic.keyDBKeychain(id: id, fieldName: "salt"))
        case .privateKey(_):
            keys.append(TypeNames.privateKey.keyDBKeychain(id: id, fieldName: "data"))
        case .hdMasterKey(_, _):
            keys.append(TypeNames.hdMasterKey.keyDBKeychain(id: id, fieldName: "data"))
        case .eos(_, _):
            keys.append(TypeNames.eos.keyDBKeychain(id: id, fieldName: "eosAccount"))
            keys.append(TypeNames.eos.keyDBKeychain(id: id, fieldName: "data"))
        }
        keys.forEach {
            try? KeychainStorage.shared.remove(for: $0)
        }
    }

}

extension Account: Equatable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }

}


final class KeychainStringArray: DatabaseValueConvertible {
    var key: String
    var array: [String]

    init?(array: [String]?, key: String) {
        guard let array = array else {
            return nil
        }
        self.array = array
        self.key = key
    }

    public var databaseValue: DatabaseValue {
        let keyInTable = key
        try? KeychainStorage.shared.set(value: array.joined(separator: ","), forKey: keyInTable)
        return keyInTable.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> KeychainStringArray? {
        guard case .string(let keyFromTable) = dbValue.storage else {
            return nil
        }
        return KeychainStringArray(array: KeychainStorage.shared.getString(forKey: keyFromTable)?.split(separator: ",").map { String($0) }, key: keyFromTable)
    }

}

final class KeychainString: DatabaseValueConvertible {
    var key: String
    var string: String

    init?(string: String?, key: String) {
        guard let string = string else {
            return nil
        }
        self.string = string
        self.key = key
    }

    public var databaseValue: DatabaseValue {
        let keyInTable = key
        try? KeychainStorage.shared.set(value: string, forKey: keyInTable)
        return keyInTable.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> KeychainString? {
        guard case .string(let keyFromTable) = dbValue.storage else {
            return nil
        }
        return KeychainString(string: KeychainStorage.shared.getString(forKey: keyFromTable), key: keyFromTable)
    }

}

final class KeychainData: DatabaseValueConvertible {
    var key: String
    var data: Data

    init?(data: Data?, key: String) {
        guard let data = data else {
            return nil
        }
        self.data = data
        self.key = key
    }

    public var databaseValue: DatabaseValue {
        let keyInTable = key
        try? KeychainStorage.shared.set(value: data, forKey: keyInTable)
        return keyInTable.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> KeychainData? {
        guard case .string(let keyFromTable) = dbValue.storage else {
            return nil
        }
        return KeychainData(data: KeychainStorage.shared.getData(forKey: keyFromTable), key: keyFromTable)
    }

}
