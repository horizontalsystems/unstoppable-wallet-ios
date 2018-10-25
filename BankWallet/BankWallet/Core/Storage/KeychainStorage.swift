import Foundation
import KeychainAccess

class KeychainStorage {
    let keychain: Keychain

    private let pinKey = "pin_keychain_key"
    private let wordsKey = "words_keychain_key"

    init(localStorage: ILocalStorage) {
        keychain = Keychain(service: "io.horizontalsystems.bank.dev")
        if !localStorage.didLaunchOnce {
            clear()
        }
    }

    func getBool(forKey key: String) -> Bool? {
        guard let string = keychain[key] else {
            return false
        }
        return Bool(string)
    }

    func set(value: Bool?, forKey key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set(value.description, key: key)
    }

    func getString(forKey key: String) -> String? {
        return keychain[key]
    }

    func set(value: String?, forKey key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set(value, key: key)
    }

    func getStringArray(forKey key: String) -> [String]? {
        if let arrayData = try? keychain.getData(key), let arrayData2 = arrayData {
            return NSKeyedUnarchiver.unarchiveObject(with: arrayData2) as? [String]
        } else {
            return nil
        }
    }

    func set(value: [String]?, forKey key: String) throws {
        guard let array = value else {
            try keychain.remove(key)
            return
        }
        let value = NSKeyedArchiver.archivedData(withRootObject: array)
        try keychain.set(value, key: key)
    }

}

extension KeychainStorage: ISecureStorage {

    var words: [String]? {
        return getStringArray(forKey: wordsKey)
    }

    func set(words: [String]?) throws {
        try set(value: words, forKey: wordsKey)
    }

    var pin: String? {
        return getString(forKey: pinKey)
    }

    func set(pin: String?) throws {
        try set(value: pin, forKey: pinKey)
    }

    func clear() {
        try? set(words: nil)
        try? set(pin: nil)
    }

}
