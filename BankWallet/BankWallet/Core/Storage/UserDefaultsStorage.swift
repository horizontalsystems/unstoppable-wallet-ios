import Foundation
import XRatesKit

class UserDefaultsStorage {
    private let keyCurrentLanguage = "current_language"
    private let keyBaseCurrencyCode = "base_currency_code"
    private let keyBaseBitcoinProvider = "base_bitcoin_provider"
    private let keyBaseBitcoinCashProvider = "base_bitcoin_cash_provider"
    private let keyBaseDashProvider = "base_dash_provider"
    private let keyBaseBinanceProvider = "base_binance_provider"
    private let keyBaseEosProvider = "base_eos_provider"
    private let keyBaseEthereumProvider = "base_ethereum_provider"
    private let keyLightMode = "light_mode"
    private let agreementAcceptedKey = "i_understand_key"
    private let balanceSortKey = "balance_sort_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let didLaunchOnceKey = "did_launch_once_key"
    private let keySendInputType = "send_input_type_key"
    private let keyChartType = "chart_type_key"
    private let mainShownOnceKey = "main_shown_once_key"
    private let debugLogKey = "debug_log_key"
    private let keyAppVersions = "app_versions"
    private let keyLockTimeEnabled = "lock_time_enabled"
    private let keyBitcoinDerivation = "bitcoin_derivation"
    private let keySyncMode = "sync_mode"

    private func value<T>(for key: String) -> T? {
        UserDefaults.standard.value(forKey: key) as? T
    }

    private func set<T>(value: T?, for key: String) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: key)
        } else  {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
    }

}

extension UserDefaultsStorage: ILocalStorage {

    var currentLanguage: String? {
        get { value(for: keyCurrentLanguage) }
        set { set(value: newValue, for: keyCurrentLanguage) }
    }

    var debugLog: String? {
        get { value(for: debugLogKey) }
        set { set(value: newValue, for: debugLogKey) }
    }

    var lastExitDate: Double {
        get { value(for: lastExitDateKey) ?? 0 }
        set { set(value: newValue, for: lastExitDateKey) }
    }

    var didLaunchOnce: Bool {
        get { value(for: didLaunchOnceKey) ?? false }
        set { set(value: newValue, for: didLaunchOnceKey) }
    }

    var baseCurrencyCode: String? {
        get { value(for: keyBaseCurrencyCode) }
        set { set(value: newValue, for: keyBaseCurrencyCode) }
    }

    var baseBitcoinProvider: String? {
        get { value(for: keyBaseBitcoinProvider) }
        set { set(value: newValue, for: keyBaseBitcoinProvider) }
    }

    var baseBitcoinCashProvider: String? {
        get { value(for: keyBaseBitcoinCashProvider) }
        set { set(value: newValue, for: keyBaseBitcoinCashProvider) }
    }

    var baseDashProvider: String? {
        get { value(for: keyBaseDashProvider) }
        set { set(value: newValue, for: keyBaseDashProvider) }
    }

    var baseBinanceProvider: String? {
        get { value(for: keyBaseBinanceProvider) }
        set { set(value: newValue, for: keyBaseBinanceProvider) }
    }

    var baseEosProvider: String? {
        get { value(for: keyBaseEosProvider) }
        set { set(value: newValue, for: keyBaseEosProvider) }
    }

    var baseEthereumProvider: String? {
        get { value(for: keyBaseEthereumProvider) }
        set { set(value: newValue, for: keyBaseEthereumProvider) }
    }

    var lightMode: Bool {
        get { value(for: keyLightMode) ?? false }
        set { set(value: newValue, for: keyLightMode) }
    }

    var agreementAccepted: Bool {
        get { value(for: agreementAcceptedKey) ?? false }
        set { set(value: newValue, for: agreementAcceptedKey) }
    }

    var balanceSortType: BalanceSortType? {
        get {
            guard let sortRawValue: Int = value(for: balanceSortKey) else {
                return nil
            }
            return BalanceSortType(rawValue: sortRawValue)
        }
        set {
            set(value: newValue?.rawValue, for: balanceSortKey)
        }
    }

    var isBiometricOn: Bool {
        get { value(for: biometricOnKey) ?? false }
        set { set(value: newValue, for: biometricOnKey) }
    }

    var sendInputType: SendInputType? {
        get {
            if let rawValue: String = value(for: keySendInputType), let value = SendInputType(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            set(value: newValue?.rawValue, for: keySendInputType)
        }
    }

    var mainShownOnce: Bool {
        get { value(for: mainShownOnceKey) ?? false }
        set { set(value: newValue, for: mainShownOnceKey) }
    }

    var appVersions: [AppVersion] {
        get {
            guard let data = UserDefaults.standard.data(forKey: keyAppVersions), let versions = try? JSONDecoder().decode([AppVersion].self, from: data) else {
                return []
            }
            return versions
        }
        set {
            UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: keyAppVersions)
        }
    }

    var lockTimeEnabled: Bool {
        get { value(for: keyLockTimeEnabled) ?? false }
        set { set(value: newValue, for: keyLockTimeEnabled) }
    }

    var bitcoinDerivation: MnemonicDerivation? {
        get {
            if let rawValue: String = value(for: keyBitcoinDerivation), let value = MnemonicDerivation(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            set(value: newValue?.rawValue, for: keyBitcoinDerivation)
        }
    }

    var syncMode: SyncMode? {
        get {
            if let rawValue: String = value(for: keySyncMode), let value = SyncMode(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            set(value: newValue?.rawValue, for: keySyncMode)
        }
    }

}

extension UserDefaultsStorage: IChartTypeStorage {

    var chartType: ChartType? {
        get {
            if let rawValue: Int = value(for: keyChartType), let type = ChartType(rawValue: rawValue) {
                return type
            }
            return nil
        }
        set {
            set(value: newValue?.rawValue, for: keyChartType)
        }
    }

}
