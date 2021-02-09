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
            let salt: String? = recover(id: id, typeName: typeName, keyName: .salt)

            type = .mnemonic(words: words, salt: salt)
        case .privateKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            type = .privateKey(data: data)
        case .zcash:
            guard let words = recoverStringArray(id: id, typeName: typeName, keyName: .words) else {
                return nil
            }

            let birthdayHeight: Int? = recover(id: id, typeName: typeName, keyName: .birthdayHeight)
            type = .zcash(words: words, birthdayHeight: birthdayHeight)
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
        var birthdayHeightKey: String?
        var dataKey: String?

        switch account.type {
        case .mnemonic(let words, let salt):
            typeName = .mnemonic
            wordsKey = try store(stringArray: words, id: id, typeName: typeName, keyName: .words)
            saltKey = try store(salt, id: id, typeName: typeName, keyName: .salt)
        case .privateKey(let data):
            typeName = .privateKey
            dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
        case .zcash(let words, let birthdayHeight):
            typeName = .zcash
            wordsKey = try store(stringArray: words, id: id, typeName: typeName, keyName: .words)
            if let height = birthdayHeight {
                birthdayHeightKey = try store(height, id: id, typeName: typeName, keyName: .birthdayHeight)
            }
        }

        return AccountRecord(
                id: id,
                name: account.name,
                type: typeName.rawValue,
                origin: account.origin.rawValue,
                backedUp: account.backedUp,
                wordsKey: wordsKey,
                saltKey: saltKey,
                birthdayHeightKey: birthdayHeightKey,
                dataKey: dataKey
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
        case .zcash:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .words))
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .birthdayHeight))
        }
    }

    private func secureKey(id: String, typeName: TypeName, keyName: KeyName) -> String {
        "\(typeName.rawValue)_\(id)_\(keyName.rawValue)"
    }

    private func store(stringArray: [String], id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        try store(stringArray.joined(separator: ","), id: id, typeName: typeName, keyName: keyName)
    }

    private func store<T: LosslessStringConvertible>(_ value: T?, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: value, for: key)
        return key
    }

    private func store(data: Data, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: data, for: key)
        return key
    }

    private func recoverStringArray(id: String, typeName: TypeName, keyName: KeyName) -> [String]? {
        let string: String? = recover(id: id, typeName: typeName, keyName: keyName)
        return string?.split(separator: ",").map { String($0) }
    }

    private func recover<T: LosslessStringConvertible>(id: String, typeName: TypeName, keyName: KeyName) -> T? {
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

    func lostAccountIds() -> [String] {
        storage.allAccountRecords.compactMap { accountRecord in
            if createAccount(record: accountRecord) == nil {
                return accountRecord.id
            }

            return nil
        }
    }

    func delete(account: Account) {
        storage.deleteAccountRecord(by: account.id)
        try? clearSecureStorage(account: account)
    }

    func delete(accountId: String) {
        storage.deleteAccountRecord(by: accountId)
    }

    func clear() {
        storage.deleteAllAccountRecords()
    }

}

extension AccountStorage {

    private enum TypeName: String {
        case mnemonic
        case privateKey
        case zcash
    }

    private enum KeyName: String {
        case words
        case salt
        case birthdayHeight
        case data
        case privateKey
    }

}
