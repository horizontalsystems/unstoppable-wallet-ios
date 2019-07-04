import Foundation

class UserDefaultsStorage: ILocalStorage {
    static let shared = UserDefaultsStorage()

    private let keySyncMode = "sync_mode_key"
    private let keyIsBackedUp = "is_backed_up"
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

    var syncMode: SyncMode? {
        get {
            guard let stringMode = getString(keySyncMode) else {
                return nil
            }
            return SyncMode(rawValue: stringMode)
        }
        set { setString(keySyncMode, value: newValue?.rawValue) }
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

    func clear() {
        syncMode = .fast
        isBackedUp = false
        lightMode = false
        agreementAccepted = false
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
