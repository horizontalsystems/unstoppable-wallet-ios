import Foundation

class UserDefaultsStorage: ILocalStorage {
    private let keyWords = "mnemonic_words"
    private let keyIsBackedUp = "is_backed_up"
    private let keyCurrentLanguage = "current_language"
    private let keyLightMode = "light_mode"
    private let iUnderstandKey = "i_understand_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"

    var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    var isBackedUp: Bool {
        get { return bool(for: keyIsBackedUp) ?? false }
        set { set(newValue, for: keyIsBackedUp) }
    }

    var currentLanguage: String? {
        get { return getString(keyCurrentLanguage) }
        set { setString(keyCurrentLanguage, value: newValue) }
    }

    var lastExitDate: Double {
        get { return double(for: lastExitDateKey) }
        set { set(newValue, for: lastExitDateKey) }
    }

    var lightMode: Bool {
        get { return bool(for: keyLightMode) ?? false }
        set { set(newValue, for: keyLightMode) }
    }

    var iUnderstand: Bool {
        get { return bool(for: iUnderstandKey) ?? false }
        set { set(newValue, for: iUnderstandKey) }
    }

    var isBiometricOn: Bool {
        get { return bool(for: biometricOnKey) ?? false }
        set { set(newValue, for: biometricOnKey) }
    }

    func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func getString(_ name: String) -> String? {
        return UserDefaults.standard.value(forKey: name) as? String
    }

    private func setString(_ name: String, value: String?) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: name)
        } else  {
            UserDefaults.standard.removeObject(forKey: name)
        }
        UserDefaults.standard.synchronize()
    }

    private func bool(for key: String) -> Bool? {
        return UserDefaults.standard.value(forKey: key) as? Bool
    }

    private func set(_ value: Bool, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    private func set(_ value: Double?, for key: String) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func double(for key: String) -> Double {
        return UserDefaults.standard.double(forKey: key)
    }

}
