import Foundation
import KeychainAccess

class KeychainHelper {
    static let shared = KeychainHelper()

    let keychain = Keychain(service: "io.horizontalsystems.bank.dev")

    func getBool(_ key: String) -> Bool? {
        guard let string = keychain[key] else {
            return false
        }
        return Bool(string)
    }

    func getString(_ key: String) -> String? {
        return keychain[key]
    }

    func set(_ value: Bool?, key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set(value.description, key: key)
    }

    func set(_ value: String?, key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set(value, key: key)
    }

}
