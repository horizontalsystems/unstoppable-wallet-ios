import Foundation

class UserDefaultsStorage: ILocalStorage {
    static let shared = UserDefaultsStorage()

    private let keyWords = "mnemonic_words"
    private let keyCurrentLanguage = "current_language"
    private let keyLightMode = "light_mode"

    var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    public var currentLanguage: String? {
        get { return getString(keyCurrentLanguage) }
        set { setString(keyCurrentLanguage, value: newValue) }
    }

    public var lightMode: Bool {
        get { return getBool(keyLightMode) ?? false }
        set { setBool(keyLightMode, value: newValue) }
    }

    func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    public func getString(_ name: String) -> String? {
        return UserDefaults.standard.value(forKey: name) as? String
    }

    public func setString(_ name: String, value: String?) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: name)
        } else  {
            UserDefaults.standard.removeObject(forKey: name)
        }
        UserDefaults.standard.synchronize()
    }

    private func getBool(_ name: String) -> Bool? {
        return UserDefaults.standard.value(forKey: name) as? Bool
    }

    private func setBool(_ name: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: name)
        UserDefaults.standard.synchronize()
    }

    public func set(_ value: Double?, for key: String) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    public func double(for key: String) -> Double? {
        return UserDefaults.standard.double(forKey: key)
    }

}
