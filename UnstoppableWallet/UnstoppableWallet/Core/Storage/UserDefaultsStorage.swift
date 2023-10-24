import Foundation

class UserDefaultsStorage {
    func value<T>(for key: String) -> T? {
        UserDefaults.standard.value(forKey: key) as? T
    }

    func set<T>(value: T?, for key: String) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
}
