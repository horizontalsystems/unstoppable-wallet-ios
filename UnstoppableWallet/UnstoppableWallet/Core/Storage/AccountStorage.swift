import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit

class AccountStorage {
    private let keychainStorage: KeychainStorage
    private let storage: AccountRecordStorage

    init(keychainStorage: KeychainStorage, storage: AccountRecordStorage) {
        self.keychainStorage = keychainStorage
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

            let compliant = record.bip39Compliant ?? (
                Mnemonic.seed(mnemonic: words, passphrase: salt) == Mnemonic.seedNonStandard(mnemonic: words, passphrase: salt)
            )

            type = .mnemonic(words: words, salt: salt, bip39Compliant: compliant)
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
        case .tronAddress:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            type = .tronAddress(address: try! TronKit.Address(raw: data))
        case .tonAddress:
            guard let address = record.dataKey else {
                return nil
            }

            type = .tonAddress(address: address)
        case .hdExtendedKey:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            guard let key = try? HDExtendedKey.deserialize(data: data) else {
                return nil
            }

            type = .hdExtendedKey(key: key)
        case .btcAddress:
            guard let address = record.wordsKey else {
                return nil
            }

            guard let tokenTypeId = record.dataKey,
                  let tokenType = TokenType(id: tokenTypeId),
                  let blockchainTypeUid = record.saltKey
            else {
                return nil
            }

            type = .btcAddress(address: address, blockchainType: BlockchainType(uid: blockchainTypeUid), tokenType: tokenType)
        case .cex:
            guard let data = recoverData(id: id, typeName: typeName, keyName: .data) else {
                return nil
            }

            let uniqueId = String(decoding: data, as: UTF8.self)

            guard let cexAccount = CexAccount.decode(uniqueId: uniqueId) else {
                return nil
            }

            type = .cex(cexAccount: cexAccount)
        }

        return Account(
            id: id,
            level: record.level,
            name: record.name,
            type: type,
            origin: origin,
            backedUp: record.backedUp,
            fileBackedUp: record.fileBackedUp
        )
    }

    private func createRecord(account: Account) throws -> AccountRecord {
        let id = account.id

        let typeName: TypeName
        var wordsKey: String?
        var saltKey: String?
        var dataKey: String?
        var bip39Compliant: Bool?

        switch account.type {
        case let .mnemonic(words, salt, compliant):
            typeName = .mnemonic
            wordsKey = try store(stringArray: words, id: id, typeName: typeName, keyName: .words)
            saltKey = try store(salt, id: id, typeName: typeName, keyName: .salt)
            bip39Compliant = compliant
        case let .evmPrivateKey(data):
            typeName = .evmPrivateKey
            dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
        case let .evmAddress(address):
            typeName = .evmAddress
            dataKey = try store(data: address.raw, id: id, typeName: typeName, keyName: .data)
        case let .tronAddress(address):
            typeName = .tronAddress
            dataKey = try store(data: address.raw, id: id, typeName: typeName, keyName: .data)
        case let .tonAddress(address):
            typeName = .tonAddress
            dataKey = address
        case let .hdExtendedKey(key):
            typeName = .hdExtendedKey
            dataKey = try store(data: key.serialized, id: id, typeName: typeName, keyName: .data)
        case let .cex(cexAccount):
            typeName = .cex
            if let data = cexAccount.uniqueId.data(using: .utf8) {
                dataKey = try store(data: data, id: id, typeName: typeName, keyName: .data)
            }
        case let .btcAddress(address, blockchainType, tokenType):
            typeName = .btcAddress
            wordsKey = address
            saltKey = blockchainType.uid
            dataKey = tokenType.id
        }

        return AccountRecord(
            id: id,
            level: account.level,
            name: account.name,
            type: typeName.rawValue,
            origin: account.origin.rawValue,
            backedUp: account.backedUp,
            fileBackedUp: account.fileBackedUp,
            wordsKey: wordsKey,
            saltKey: saltKey,
            dataKey: dataKey,
            bip39Compliant: bip39Compliant
        )
    }

    private func clearSecureStorage(account: Account) throws {
        let id = account.id

        switch account.type {
        case .mnemonic:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .words))
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .salt))
        case .evmPrivateKey:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .evmPrivateKey, keyName: .data))
        case .evmAddress:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .evmAddress, keyName: .data))
        case .tronAddress:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .tronAddress, keyName: .data))
        case .hdExtendedKey:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .hdExtendedKey, keyName: .data))
        case .btcAddress:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .btcAddress, keyName: .data))
        case .cex:
            try keychainStorage.removeValue(for: secureKey(id: id, typeName: .cex, keyName: .data))
        default:
            ()
        }
    }

    private func secureKey(id: String, typeName: TypeName, keyName: KeyName) -> String {
        "\(typeName.rawValue)_\(id)_\(keyName.rawValue)"
    }

    private func store(stringArray: [String], id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        try store(stringArray.joined(separator: ","), id: id, typeName: typeName, keyName: keyName)
    }

    private func store(_ value: some LosslessStringConvertible, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try keychainStorage.set(value: value, for: key)
        return key
    }

    private func store(data: Data, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try keychainStorage.set(value: data, for: key)
        return key
    }

    private func recoverStringArray(id: String, typeName: TypeName, keyName: KeyName) -> [String]? {
        let string: String? = recover(id: id, typeName: typeName, keyName: keyName)
        return string?.split(separator: ",").map { String($0) }
    }

    private func recover<T: LosslessStringConvertible>(id: String, typeName: TypeName, keyName: KeyName) -> T? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return keychainStorage.value(for: key)
    }

    private func recoverData(id: String, typeName: TypeName, keyName: KeyName) -> Data? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return keychainStorage.value(for: key)
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
        case tronAddress
        case tonAddress
        case hdExtendedKey
        case btcAddress
        case cex
    }

    private enum KeyName: String {
        case words
        case salt
        case data
    }
}
