import Foundation

class UserDefaultsStorage {
    func value<T>(for key: String) -> T? {
        UserDefaults.standard.value(forKey: key) as? T
    }

    func set(value: (some Any)?, for key: String) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
}
