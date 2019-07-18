import Foundation
import KeychainAccess

class KeychainStorage {
    static let shared: ISecureStorage = KeychainStorage(localStorage: UserDefaultsStorage.shared)

    private let keychain: Keychain

    private let pinKey = "pin_keychain_key"
    private let authDataKey = "auth_data_keychain_key"
    private let unlockAttemptsKey = "unlock_attempts_keychain_key"
    private let lockTimestampKey = "lock_timestamp_keychain_key"

    init(localStorage: ILocalStorage) {
        keychain = Keychain(service: "io.horizontalsystems.bank.dev")

        if !localStorage.didLaunchOnce {
            try? keychain.removeAll()
            localStorage.didLaunchOnce = true
        }
    }

    private func getBool(forKey key: String) -> Bool? {
        guard let string = keychain[key] else {
            return false
        }
        return Bool(string)
    }

    private func set(value: Bool?, forKey key: String) throws {
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

    private func getInt(forKey key: String) -> Int? {
        guard let string = keychain[key] else {
            return nil
        }
        return Int(string)
    }

    private func set(value: Int?, forKey key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set("\(value)", key: key)
    }

    private func getDouble(forKey key: String) -> Double? {
        guard let string = keychain[key] else {
            return nil
        }
        return Double(string)
    }

    private func set(value: Double?, forKey key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set("\(value)", key: key)
    }

    func getData(forKey key: String) -> Data? {
        return try? keychain.getData(key)
    }

    func set(value: Data?, forKey key: String) throws {
        guard let value = value else {
            try keychain.remove(key)
            return
        }
        try keychain.set(value, key: key)
    }

    private func get<T: NSCoding>(forKey key: String) -> T? {
        if let keychainData = try? keychain.getData(key) {
            return NSKeyedUnarchiver.unarchiveObject(with: keychainData) as? T
        } else {
            return nil
        }
    }

    private func set<T: NSCoding>(value: T?, forKey key: String) throws {
        if let value = value {
            let data = NSKeyedArchiver.archivedData(withRootObject: value)
            try keychain.set(data, key: key)
        } else {
            try keychain.remove(key)
        }
    }

    func remove(for key: String) throws {
        try keychain.remove(key)
    }

}

extension KeychainStorage: ISecureStorage {

    var authData: AuthData? {
        return get(forKey: authDataKey)
    }

    func set(authData: AuthData?) throws {
        try set(value: authData, forKey: authDataKey)
    }

    var pin: String? {
        return getString(forKey: pinKey)
    }

    func set(pin: String?) throws {
        try set(value: pin, forKey: pinKey)
    }

    var unlockAttempts: Int? {
        return getInt(forKey: unlockAttemptsKey)
    }

    func set(unlockAttempts: Int?) throws {
        try set(value: unlockAttempts, forKey: unlockAttemptsKey)
    }

    var lockoutTimestamp: TimeInterval? {
        guard let double = getDouble(forKey: lockTimestampKey) else {
            return nil
        }
        return TimeInterval(double)
    }

    func set(lockoutTimestamp: Double?) throws {
        try set(value: lockoutTimestamp, forKey: lockTimestampKey)
    }

}
