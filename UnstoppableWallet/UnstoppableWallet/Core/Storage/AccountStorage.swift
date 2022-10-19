import Foundation
import StorageKit
import EvmKit
import HdWalletKit

class AccountStorage {
    private let secureStorage: ISecureStorage
    private let storage: AccountRecordStorage

    init(secureStorage: ISecureStorage, storage: AccountRecordStorage) {
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
            guard let salt: String = recover(id: id, typeName: typeName, keyName: .salt) else {
                return nil
            }

            type = .mnemonic(words: words, salt: salt)
        case .evmPrivateKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            type = .evmPrivateKey(data: data)
        case .evmAddress:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            type = .evmAddress(address: EvmKit.Address(raw: data))
        case .hdExtendedKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            guard let key = try? HDExtendedKey.deserialize(data: data) else {
                return nil
            }

            type = .hdExtendedKey(key: key)
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

        switch account.type {
        case .mnemonic(let words, let salt):
            typeName = .mnemonic
            wordsKey = try store(stringArray: words, id: id, typeName: typeName, keyName: .words)
            saltKey = try store(salt, id: id, typeName: typeName, keyName: .salt)
        case .evmPrivateKey(let data):
            typeName = .evmPrivateKey
            dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
        case .evmAddress(let address):
            typeName = .evmAddress
            dataKey = try store(data: address.raw, id: id, typeName: typeName, keyName: .data)
        case .hdExtendedKey(let key):
            typeName = .hdExtendedKey
            dataKey = try store(data: key.serialized, id: id, typeName: typeName, keyName: .data)
        }

        return AccountRecord(
                id: id,
                name: account.name,
                type: typeName.rawValue,
                origin: account.origin.rawValue,
                backedUp: account.backedUp,
                wordsKey: wordsKey,
                saltKey: saltKey,
                dataKey: dataKey
        )
    }

    private func clearSecureStorage(account: Account) throws {
        let id = account.id

        switch account.type {
        case .mnemonic:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .words))
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .salt))
        case .evmPrivateKey:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .evmPrivateKey, keyName: .data))
        case .evmAddress:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .evmAddress, keyName: .data))
        case .hdExtendedKey:
            try secureStorage.removeValue(for: secureKey(id: id, typeName: .hdExtendedKey, keyName: .data))
        }
    }

    private func secureKey(id: String, typeName: TypeName, keyName: KeyName) -> String {
        "\(typeName.rawValue)_\(id)_\(keyName.rawValue)"
    }

    private func store(stringArray: [String], id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        try store(stringArray.joined(separator: ","), id: id, typeName: typeName, keyName: keyName)
    }

    private func store<T: LosslessStringConvertible>(_ value: T, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
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

extension AccountStorage {

    var allAccounts: [Account] {
        storage.all.compactMap { createAccount(record: $0) }
    }

    func save(account: Account) {
        if let record = try? createRecord(account: account) {
            storage.save(record: record)
        }
    }

    var lostAccountIds: [String] {
        storage.all.compactMap { accountRecord in
            if createAccount(record: accountRecord) == nil {
                return accountRecord.id
            }

            return nil
        }
    }

    func delete(account: Account) {
        storage.delete(by: account.id)
        try? clearSecureStorage(account: account)
    }

    func delete(accountId: String) {
        storage.delete(by: accountId)
    }

    func clear() {
        storage.clear()
    }

}

extension AccountStorage {

    private enum TypeName: String {
        case mnemonic
        case evmPrivateKey
        case evmAddress = "address"
        case hdExtendedKey
    }

    private enum KeyName: String {
        case words
        case salt
        case data
    }

}
