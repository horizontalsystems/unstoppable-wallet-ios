import Foundation

class UserDefaultsStorage: ILocalStorage {
    private let keyIsNewWallet = "is_new_wallet"
    private let keyIsBackedUp = "is_backed_up"
    private let keyCurrentLanguage = "current_language"
    private let keyBaseCurrencyCode = "base_currency_code"
    private let keyBaseBitcoinProvider = "base_bitcoin_provider"
    private let keyBaseEthereumProvider = "base_ethereum_provider"
    private let keyLightMode = "light_mode"
    private let iUnderstandKey = "i_understand_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let didLaunchOnceKey = "did_launch_once_key"
    private let keySendInputType = "send_input_type_key"

    var isNewWallet: Bool {
        get { return bool(for: keyIsNewWallet) ?? false }
        set { set(newValue, for: keyIsNewWallet) }
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

    var didLaunchOnce: Bool {
        if bool(for: didLaunchOnceKey) ?? false {
            return true
        }
        set(true, for: didLaunchOnceKey)
        return false
    }

    var baseCurrencyCode: String? {
        get { return getString(keyBaseCurrencyCode) }
        set { setString(keyBaseCurrencyCode, value: newValue) }
    }

    var baseBitcoinProvider: String? {
        get { return getString(keyBaseBitcoinProvider) }
        set { setString(keyBaseBitcoinProvider, value: newValue) }
    }

    var baseEthereumProvider: String? {
        get { return getString(keyBaseEthereumProvider) }
        set { setString(keyBaseEthereumProvider, value: newValue) }
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

    var sendInputType: SendInputType? {
        get {
            if let rawValue = getString(keySendInputType), let value = SendInputType(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            setString(keySendInputType, value: newValue?.rawValue)
        }
    }

    func clear() {
        isNewWallet = false
        isBackedUp = false
        lightMode = false
        iUnderstand = false
        isBiometricOn = false
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
