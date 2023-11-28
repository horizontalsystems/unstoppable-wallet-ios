import Foundation
import KeychainAccess

class KeychainStorage {
    private let keychain: Keychain

    init(service: String) {
        keychain = Keychain(service: service).accessibility(.whenPasscodeSetThisDeviceOnly)
    }
}

extension KeychainStorage {
    func value<T: LosslessStringConvertible>(for key: String) -> T? {
        guard let string = keychain[key] else {
            return nil
        }
        return T(string)
    }

    func set(value: (some LosslessStringConvertible)?, for key: String) throws {
        if let value {
            try keychain.set(value.description, key: key)
        } else {
            try keychain.remove(key)
        }
    }

    func value(for key: String) -> Data? {
        try? keychain.getData(key)
    }

    func set(value: Data?, for key: String) throws {
        if let value {
            try keychain.set(value, key: key)
        } else {
            try keychain.remove(key)
        }
    }

    func removeValue(for key: String) throws {
        try keychain.remove(key)
    }

    func clear() throws {
        try keychain.removeAll()
    }
}
