import Foundation
import StorageKit
import XRatesKit

class LocalStorage {
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

    private let storage: StorageKit.ILocalStorage

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage
    }

}

extension LocalStorage: ILocalStorage {

    var debugLog: String? {
        get { storage.value(for: debugLogKey) }
        set { storage.set(value: newValue, for: debugLogKey) }
    }

    var baseBitcoinProvider: String? {
        get { storage.value(for: keyBaseBitcoinProvider) }
        set { storage.set(value: newValue, for: keyBaseBitcoinProvider) }
    }

    var baseBitcoinCashProvider: String? {
        get { storage.value(for: keyBaseBitcoinCashProvider) }
        set { storage.set(value: newValue, for: keyBaseBitcoinCashProvider) }
    }

    var baseDashProvider: String? {
        get { storage.value(for: keyBaseDashProvider) }
        set { storage.set(value: newValue, for: keyBaseDashProvider) }
    }

    var baseBinanceProvider: String? {
        get { storage.value(for: keyBaseBinanceProvider) }
        set { storage.set(value: newValue, for: keyBaseBinanceProvider) }
    }

    var baseEosProvider: String? {
        get { storage.value(for: keyBaseEosProvider) }
        set { storage.set(value: newValue, for: keyBaseEosProvider) }
    }

    var baseEthereumProvider: String? {
        get { storage.value(for: keyBaseEthereumProvider) }
        set { storage.set(value: newValue, for: keyBaseEthereumProvider) }
    }

    var agreementAccepted: Bool {
        get { storage.value(for: agreementAcceptedKey) ?? false }
        set { storage.set(value: newValue, for: agreementAcceptedKey) }
    }

    var balanceSortType: BalanceSortType? {
        get {
            guard let sortRawValue: Int = storage.value(for: balanceSortKey) else {
                return nil
            }
            return BalanceSortType(rawValue: sortRawValue)
        }
        set {
            storage.set(value: newValue?.rawValue, for: balanceSortKey)
        }
    }

    var sendInputType: SendInputType? {
        get {
            if let rawValue: String = storage.value(for: keySendInputType), let value = SendInputType(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            storage.set(value: newValue?.rawValue, for: keySendInputType)
        }
    }

    var mainShownOnce: Bool {
        get { storage.value(for: mainShownOnceKey) ?? false }
        set { storage.set(value: newValue, for: mainShownOnceKey) }
    }

    var appVersions: [AppVersion] {
        get {
            guard let data: Data = storage.value(for: keyAppVersions), let versions = try? JSONDecoder().decode([AppVersion].self, from: data) else {
                return []
            }
            return versions
        }
        set {
            storage.set(value: try? JSONEncoder().encode(newValue), for: keyAppVersions)
        }
    }

    var lockTimeEnabled: Bool {
        get { storage.value(for: keyLockTimeEnabled) ?? false }
        set { storage.set(value: newValue, for: keyLockTimeEnabled) }
    }

}

extension LocalStorage: IChartTypeStorage {

    var chartType: ChartType? {
        get {
            if let rawValue: Int = storage.value(for: keyChartType), let type = ChartType(rawValue: rawValue) {
                return type
            }
            return nil
        }
        set {
            storage.set(value: newValue?.rawValue, for: keyChartType)
        }
    }

}
