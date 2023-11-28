import Foundation

struct SharedLocalStorage {
    func value<T>(for key: String) -> T? {
        userDefaults?.value(forKey: key) as? T
    }

    func set(value: (some Any)?, for key: String) {
        guard let userDefaults else {
            return
        }

        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }

        userDefaults.synchronize()
    }

    private var userDefaults: UserDefaults? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return nil
        }

        return UserDefaults(suiteName: "group.\(bundleIdentifier.replacingOccurrences(of: ".widget", with: ""))")
    }
}
