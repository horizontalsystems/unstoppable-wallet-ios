import Foundation
import GRDB

class AccountRecord: Record {
    enum AccountError: Error { case invalidContent }

    private let id: String
    private var name: String
    var backedUp: Bool
    private var defaultSyncMode: SyncMode?

    private var type: TypeNames
    var words: EncryptedStringArray?
    private var derivation: MnemonicDerivation?
    var salt: EncryptedString?
    var data: EncryptedData?
    var eosAccount: EncryptedString?

    init(account: Account) {
        self.id = account.id
        self.name = account.name
        self.backedUp = account.backedUp
        self.defaultSyncMode = account.defaultSyncMode
        switch account.type {
        case .mnemonic(let words, let derivation, let salt):
            self.type = .mnemonic
            self.words = EncryptedStringArray(array: words, key: self.type.keyDBKeychain(id: id, fieldName: "words"))
            self.derivation = derivation
            self.salt = EncryptedString(string: salt, key: self.type.keyDBKeychain(id: id, fieldName: "salt"))
        case .privateKey(let data):
            self.type = .privateKey
            self.data = EncryptedData(data: data, key: self.type.keyDBKeychain(id: id, fieldName: "data"))
        case .hdMasterKey(let data, let derivation):
            self.type = TypeNames.hdMasterKey
            self.data = EncryptedData(data: data, key: self.type.keyDBKeychain(id: id, fieldName: "data"))
            self.derivation = derivation
        case .eos(let account, let activePrivateKey):
            self.type = TypeNames.eos
            self.eosAccount = EncryptedString(string: account, key: self.type.keyDBKeychain(id: id, fieldName: "eosAccount"))
            self.data = EncryptedData(data: activePrivateKey, key: self.type.keyDBKeychain(id: id, fieldName: "data"))
        }

        super.init()
    }

    func update(with account: Account) {
        name = account.name
        backedUp = account.backedUp
        defaultSyncMode = account.defaultSyncMode

        switch account.type {
        case .mnemonic(let words, let derivation, let salt):
            self.words?.array = words
            self.derivation = derivation
            if let salt = salt {
                self.salt?.string = salt
            }
        case .privateKey(let data):
            self.data?.data = data
        case .hdMasterKey(let data, let derivation):
            self.data?.data = data
            self.derivation = derivation
        case .eos(let account, let activePrivateKey):
            self.eosAccount?.string = account
            self.data?.data = activePrivateKey
        }
    }

    func getAccount() throws -> Account {
        var accountType: AccountType
        switch type {
        case .mnemonic:
            guard let words = words, let derivation = derivation else {
                throw AccountError.invalidContent
            }
            accountType = .mnemonic(words: words.array, derivation: derivation, salt: salt?.string)
        case .privateKey:
            guard let data = data else {
                throw AccountError.invalidContent
            }
            accountType = .privateKey(data: data.data)
        case .hdMasterKey:
            guard let data = data, let derivation = derivation else {
                throw AccountError.invalidContent
            }
            accountType = .hdMasterKey(data: data.data, derivation: derivation)
        case .eos:
            guard let eosAccount = eosAccount, let data = data else {
                throw AccountError.invalidContent
            }
            accountType = .eos(account: eosAccount.string, activePrivateKey: data.data)
        }
        return Account(id: id, name: name, type: accountType, backedUp: backedUp, defaultSyncMode: defaultSyncMode)
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
        type = row[Columns.type]
        switch type {
        case .mnemonic:
            words = row[Columns.words]
            derivation = row[Columns.derivation]
            salt = row[Columns.salt]
        case .privateKey:
            data = row[Columns.data]
        case .hdMasterKey:
            data = row[Columns.data]
            derivation = row[Columns.derivation]
        case .eos:
            eosAccount = row[Columns.eosAccount]
            data = row[Columns.data]
        }
        backedUp = row[Columns.backedUp]
        defaultSyncMode = row[Columns.defaultSyncMode]
        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.type] = type
        switch type {
        case .mnemonic:
            container[Columns.words] = words
            container[Columns.derivation] = derivation
            container[Columns.salt] = salt
        case .privateKey:
            container[Columns.data] = data
        case .hdMasterKey:
            container[Columns.data] = data
            container[Columns.derivation] = derivation
        case .eos:
            container[Columns.eosAccount] = eosAccount
            container[Columns.data] = data
        }
        container[Columns.backedUp] = backedUp
        container[Columns.defaultSyncMode] = defaultSyncMode
    }

}

final class EncryptedStringArray: DatabaseValueConvertible {
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

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> EncryptedStringArray? {
        guard case .string(let keyFromTable) = dbValue.storage else {
            return nil
        }
        return EncryptedStringArray(array: KeychainStorage.shared.getString(forKey: keyFromTable)?.split(separator: ",").map { String($0) }, key: keyFromTable)
    }

}

final class EncryptedString: DatabaseValueConvertible {
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

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> EncryptedString? {
        guard case .string(let keyFromTable) = dbValue.storage else {
            return nil
        }
        return EncryptedString(string: KeychainStorage.shared.getString(forKey: keyFromTable), key: keyFromTable)
    }

}

final class EncryptedData: DatabaseValueConvertible {
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

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> EncryptedData? {
        guard case .string(let keyFromTable) = dbValue.storage else {
            return nil
        }
        return EncryptedData(data: KeychainStorage.shared.getData(forKey: keyFromTable), key: keyFromTable)
    }

}