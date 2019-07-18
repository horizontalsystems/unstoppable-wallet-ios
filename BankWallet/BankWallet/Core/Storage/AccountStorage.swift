import KeychainAccess

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

        let id = record.id
        let type: AccountType

        switch typeName {
        case .mnemonic:
            guard let words = recoverStringArray(id: id, typeName: typeName, keyName: .words) else {
                return nil
            }
            guard let derivation = record.derivation.flatMap({ MnemonicDerivation(rawValue: $0) }) else {
                return nil
            }
            let salt = recoverString(id: id, typeName: typeName, keyName: .salt)

            type = .mnemonic(words: words, derivation: derivation, salt: salt)
        case .privateKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            type = .privateKey(data: data)
        case .hdMasterKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }
            guard let derivation = record.derivation.flatMap({ MnemonicDerivation(rawValue: $0) }) else {
                return nil
            }

            type = .hdMasterKey(data: data, derivation: derivation)
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
                backedUp: record.backedUp,
                defaultSyncMode: record.defaultSyncMode.flatMap { SyncMode(rawValue: $0) }
        )
    }

    private func createRecord(account: Account) throws -> AccountRecord {
        let id = account.id

        let typeName: TypeName
        var wordsKey: String?
        var derivation: MnemonicDerivation?
        var saltKey: String?
        var dataKey: String?
        var eosAccount: String?

        switch account.type {
        case .mnemonic(let words, let _derivation, let salt):
            typeName = .mnemonic
            wordsKey = try store(stringArray: words, id: id, typeName: typeName, keyName: .words)
            derivation = _derivation
            saltKey = try store(string: salt, id: id, typeName: typeName, keyName: .salt)
        case .privateKey(let data):
            typeName = .privateKey
            dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
        case .hdMasterKey(let data, let _derivation):
            typeName = .hdMasterKey
            dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
            derivation = _derivation
        case .eos(let account, let activePrivateKey):
            typeName = .eos
            eosAccount = account
            dataKey = try store(string: activePrivateKey, id: id, typeName: typeName, keyName: .privateKey)
        }

        return AccountRecord(
                id: id,
                name: account.name,
                type: typeName.rawValue,
                backedUp: account.backedUp,
                defaultSyncMode: account.defaultSyncMode?.rawValue,
                wordsKey: wordsKey,
                derivation: derivation?.rawValue,
                saltKey: saltKey,
                dataKey: dataKey,
                eosAccount: eosAccount
        )
    }

    private func clearSecureStorage(account: Account) throws {
        let id = account.id

        switch account.type {
        case .mnemonic:
            try secureStorage.remove(for: secureKey(id: id, typeName: .mnemonic, keyName: .words))
            try secureStorage.remove(for: secureKey(id: id, typeName: .mnemonic, keyName: .salt))
        case .privateKey:
            try secureStorage.remove(for: secureKey(id: id, typeName: .privateKey, keyName: .data))
        case .hdMasterKey:
            try secureStorage.remove(for: secureKey(id: id, typeName: .hdMasterKey, keyName: .data))
        case .eos:
            try secureStorage.remove(for: secureKey(id: id, typeName: .eos, keyName: .privateKey))
        }
    }

    private func secureKey(id: String, typeName: TypeName, keyName: KeyName) -> String {
        return "\(typeName.rawValue)_\(id)_\(keyName.rawValue)"
    }

    private func store(stringArray: [String], id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        return try store(string: stringArray.joined(separator: ","), id: id, typeName: typeName, keyName: keyName) 
    }

    private func store(string: String?, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: string, forKey: key)
        return key
    }

    private func store(data: Data, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: data, forKey: key)
        return key
    }

    private func recoverStringArray(id: String, typeName: TypeName, keyName: KeyName) -> [String]? {
        return recoverString(id: id, typeName: typeName, keyName: keyName)?.split(separator: ",").map { String($0) }
    }

    private func recoverString(id: String, typeName: TypeName, keyName: KeyName) -> String? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return secureStorage.getString(forKey: key)
    }

    private func recoverData(id: String, typeName: TypeName, keyName: KeyName) -> Data? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return secureStorage.getData(forKey: key)
    }

}

extension AccountStorage: IAccountStorage {

    var allAccounts: [Account] {
        return storage.allAccountRecords.compactMap { createAccount(record: $0) }
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

}

extension AccountStorage {

    private enum TypeName: String {
        case mnemonic
        case privateKey
        case hdMasterKey
        case eos
    }

    private enum KeyName: String {
        case words
        case salt
        case data
        case privateKey
    }

}
