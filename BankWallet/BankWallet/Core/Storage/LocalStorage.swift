import Foundation
import StorageKit
import XRatesKit

class LocalStorage {
    private let keyBaseCurrencyCode = "base_currency_code"
    private let keyBaseBitcoinProvider = "base_bitcoin_provider"
    private let keyBaseBitcoinCashProvider = "base_bitcoin_cash_provider"
    private let keyBaseDashProvider = "base_dash_provider"
    private let keyBaseBinanceProvider = "base_binance_provider"
    private let keyBaseEosProvider = "base_eos_provider"
    private let keyBaseEthereumProvider = "base_ethereum_provider"
    private let agreementAcceptedKey = "i_understand_key"
    private let balanceSortKey = "balance_sort_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let keySendInputType = "send_input_type_key"
    private let keyChartType = "chart_type_key"
    private let mainShownOnceKey = "main_shown_once_key"
    private let debugLogKey = "debug_log_key"
    private let keyAppVersions = "app_versions"
    private let keyLockTimeEnabled = "lock_time_enabled"
}

extension LocalStorage: ILocalStorage {

    var debugLog: String? {
        get { Kit.localStorage.value(for: debugLogKey) }
        set { Kit.localStorage.set(value: newValue, for: debugLogKey) }
    }

    var lastExitDate: Double {
        get { Kit.localStorage.value(for: lastExitDateKey) ?? 0 }
        set { Kit.localStorage.set(value: newValue, for: lastExitDateKey) }
    }

    var baseCurrencyCode: String? {
        get { Kit.localStorage.value(for: keyBaseCurrencyCode) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseCurrencyCode) }
    }

    var baseBitcoinProvider: String? {
        get { Kit.localStorage.value(for: keyBaseBitcoinProvider) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseBitcoinProvider) }
    }

    var baseBitcoinCashProvider: String? {
        get { Kit.localStorage.value(for: keyBaseBitcoinCashProvider) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseBitcoinCashProvider) }
    }

    var baseDashProvider: String? {
        get { Kit.localStorage.value(for: keyBaseDashProvider) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseDashProvider) }
    }

    var baseBinanceProvider: String? {
        get { Kit.localStorage.value(for: keyBaseBinanceProvider) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseBinanceProvider) }
    }

    var baseEosProvider: String? {
        get { Kit.localStorage.value(for: keyBaseEosProvider) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseEosProvider) }
    }

    var baseEthereumProvider: String? {
        get { Kit.localStorage.value(for: keyBaseEthereumProvider) }
        set { Kit.localStorage.set(value: newValue, for: keyBaseEthereumProvider) }
    }

    var agreementAccepted: Bool {
        get { Kit.localStorage.value(for: agreementAcceptedKey) ?? false }
        set { Kit.localStorage.set(value: newValue, for: agreementAcceptedKey) }
    }

    var balanceSortType: BalanceSortType? {
        get {
            guard let sortRawValue: Int = Kit.localStorage.value(for: balanceSortKey) else {
                return nil
            }
            return BalanceSortType(rawValue: sortRawValue)
        }
        set {
            Kit.localStorage.set(value: newValue?.rawValue, for: balanceSortKey)
        }
    }

    var isBiometricOn: Bool {
        get { Kit.localStorage.value(for: biometricOnKey) ?? false }
        set { Kit.localStorage.set(value: newValue, for: biometricOnKey) }
    }

    var sendInputType: SendInputType? {
        get {
            if let rawValue: String = Kit.localStorage.value(for: keySendInputType), let value = SendInputType(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            Kit.localStorage.set(value: newValue?.rawValue, for: keySendInputType)
        }
    }

    var mainShownOnce: Bool {
        get { Kit.localStorage.value(for: mainShownOnceKey) ?? false }
        set { Kit.localStorage.set(value: newValue, for: mainShownOnceKey) }
    }

    var appVersions: [AppVersion] {
        get {
            guard let data: Data = Kit.localStorage.value(for: keyAppVersions), let versions = try? JSONDecoder().decode([AppVersion].self, from: data) else {
                return []
            }
            return versions
        }
        set {
            Kit.localStorage.set(value: try? JSONEncoder().encode(newValue), for: keyAppVersions)
        }
    }

    var lockTimeEnabled: Bool {
        get { Kit.localStorage.value(for: keyLockTimeEnabled) ?? false }
        set { Kit.localStorage.set(value: newValue, for: keyLockTimeEnabled) }
    }

}

extension LocalStorage: IChartTypeStorage {

    var chartType: ChartType? {
        get {
            if let rawValue: Int = Kit.localStorage.value(for: keyChartType), let type = ChartType(rawValue: rawValue) {
                return type
            }
            return nil
        }
        set {
            Kit.localStorage.set(value: newValue?.rawValue, for: keyChartType)
        }
    }

}
