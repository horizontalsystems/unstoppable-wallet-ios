import Foundation

class UserDefaultsStorage {
    private let keyCurrentLanguage = "current_language"
    private let keyBaseCurrencyCode = "base_currency_code"
    private let keyBaseBitcoinProvider = "base_bitcoin_provider"
    private let keyBaseDashProvider = "base_dash_provider"
    private let keyBaseEthereumProvider = "base_ethereum_provider"
    private let keyLightMode = "light_mode"
    private let agreementAcceptedKey = "i_understand_key"
    private let balanceSortKey = "balance_sort_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let didLaunchOnceKey = "did_launch_once_key"
    private let keySendInputType = "send_input_type_key"
    private let didShowMainOnceKey = "did_show_main_once_key"

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

extension UserDefaultsStorage: ILocalStorage {

    var currentLanguage: String? {
        get { return getString(keyCurrentLanguage) }
        set { setString(keyCurrentLanguage, value: newValue) }
    }

    var lastExitDate: Double {
        get { return double(for: lastExitDateKey) }
        set { set(newValue, for: lastExitDateKey) }
    }

    var didLaunchOnce: Bool {
        get { return bool(for: didLaunchOnceKey) ?? false }
        set { set(newValue, for: didLaunchOnceKey) }
    }

    var baseCurrencyCode: String? {
        get { return getString(keyBaseCurrencyCode) }
        set { setString(keyBaseCurrencyCode, value: newValue) }
    }

    var baseBitcoinProvider: String? {
        get { return getString(keyBaseBitcoinProvider) }
        set { setString(keyBaseBitcoinProvider, value: newValue) }
    }

    var baseDashProvider: String? {
        get { return getString(keyBaseDashProvider) }
        set { setString(keyBaseDashProvider, value: newValue) }
    }

    var baseEthereumProvider: String? {
        get { return getString(keyBaseEthereumProvider) }
        set { setString(keyBaseEthereumProvider, value: newValue) }
    }

    var lightMode: Bool {
        get { return bool(for: keyLightMode) ?? false }
        set { set(newValue, for: keyLightMode) }
    }

    var agreementAccepted: Bool {
        get { return bool(for: agreementAcceptedKey) ?? false }
        set { set(newValue, for: agreementAcceptedKey) }
    }

    var balanceSortType: BalanceSortType? {
        get {
            guard let stringSort = getString(balanceSortKey), let intSort = Int(stringSort) else {
                return nil
            }
            return BalanceSortType(rawValue: intSort)
        }
        set {
            if let newValue = newValue?.rawValue {
                setString(balanceSortKey, value: "\(newValue)")
            } else {
                setString(balanceSortKey, value: nil)
            }
        }
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

    var didShowMainOnce: Bool {
        get { return bool(for: didShowMainOnceKey) ?? false }
        set { set(newValue, for: didShowMainOnceKey) }
    }

}
