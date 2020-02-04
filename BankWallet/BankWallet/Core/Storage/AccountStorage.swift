import StorageKit

class AccountStorage {
    private let secureStorage: ISecureStorage
    private let storage: IAccountRecordStorage

    init(secureStorage: ISecureStorage, storage: IAccountRecordStorage) {
        self.secureStorage = secureStorage
        self.storage = storage
    }

    private func createAccount(record: AccountRecord) -> Account? {
        guard let typeName = TypeName(rawValue: record.type) else {
            return nil
        }

        guard let origin = AccountOrigin(rawValue: record.origin) else {
            return nil
        }

        let id = record.id
        let type: AccountType

        switch typeName {
        case .mnemonic:
            guard let words = recoverStringArray(id: id, typeName: typeName, keyName: .words) else {
                return nil
            }
            let salt = recoverString(id: id, typeName: typeName, keyName: .salt)

            type = .mnemonic(words: words, salt: salt)
        case .privateKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            type = .privateKey(data: data)
        case .eos:
            guard let eosAccount = record.eosAccount else {
                return nil
            }
            guard let activePrivateKey = recoverString(id: id, typeName: typeName, keyName: .privateKey) else {
                return nil
            }

            type = .eos(account: eosAccount, activePrivateKey: activePrivateKey)
        }

        return Account(
                id: id,
                name: record.name,
                type: type,
                origin: origin,
                backedUp: record.backedUp
        )
    }

    private func createRecord(account: Account) throws -> AccountRecord {
        let id = account.id

        let typeName: TypeName
        var wordsKey: String?
        var saltKey: String?
        var dataKey: String?
        var eosAccount: String?

        switch account.type {
        case .mnemonic(let words, let salt):
            typeName = .mnemonic
            wordsKey = try store(stringArray: words, id: id, typeName: typeName, keyName: .words)
            saltKey = try store(string: salt, id: id, typeName: typeName, keyName: .salt)
        case .privateKey(let data):
            typeName = .privateKey
            dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
        case .eos(let account, let activePrivateKey):
            typeName = .eos
            eosAccount = account
            dataKey = try store(string: activePrivateKey, id: id, typeName: typeName, keyName: .privateKey)
        }

        return AccountRecord(
                id: id,
                name: account.name,
                type: typeName.rawValue,
                origin: account.origin.rawValue,
                backedUp: account.backedUp,
                wordsKey: wordsKey,
                saltKey: saltKey,
                dataKey: dataKey,
                eosAccount: eosAccount
        )
    }

    private func clearSecureStorage(account: Account) throws {
        let id = account.id

        switch account.type {
        case .mnemonic:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .words))
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .salt))
        case .privateKey:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .privateKey, keyName: .data))
        case .eos:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .eos, keyName: .privateKey))
        }
    }

    private func secureKey(id: String, typeName: TypeName, keyName: KeyName) -> String {
        "\(typeName.rawValue)_\(id)_\(keyName.rawValue)"
    }

    private func store(stringArray: [String], id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        try store(string: stringArray.joined(separator: ","), id: id, typeName: typeName, keyName: keyName) 
    }

    private func store(string: String?, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: string, for: key)
        return key
    }

    private func store(data: Data, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: data, for: key)
        return key
    }

    private func recoverStringArray(id: String, typeName: TypeName, keyName: KeyName) -> [String]? {
        recoverString(id: id, typeName: typeName, keyName: keyName)?.split(separator: ",").map { String($0) }
    }

    private func recoverString(id: String, typeName: TypeName, keyName: KeyName) -> String? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return secureStorage.value(for: key)
    }

    private func recoverData(id: String, typeName: TypeName, keyName: KeyName) -> Data? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return secureStorage.value(for: key)
    }

}

extension AccountStorage: IAccountStorage {

    var allAccounts: [Account] {
        storage.allAccountRecords.compactMap { createAccount(record: $0) }
    }

    func save(account: Account) {
        if let record = try? createRecord(account: account) {
            storage.save(accountRecord: record)
        }
    }

    func delete(account: Account) {
        storage.deleteAccountRecord(by: account.id)
        try? clearSecureStorage(account: account)
    }

    func clear() {
        storage.deleteAllAccountRecords()
    }

}

extension AccountStorage {

    private enum TypeName: String {
        case mnemonic
        case privateKey
        case eos
    }

    private enum KeyName: String {
        case words
        case salt
        case data
        case privateKey
    }

}
