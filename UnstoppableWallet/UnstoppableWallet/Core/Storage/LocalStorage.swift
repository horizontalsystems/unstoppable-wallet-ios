import Foundation
import StorageKit
import MarketKit

class LocalStorage {
    private let agreementAcceptedKey = "i_understand_key"
    private let keySortType = "balance_sort_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let keySendInputType = "send_input_type_key"
    private let keyChartType = "chart_type_key"
    private let mainShownOnceKey = "main_shown_once_key"
    private let jailbreakShownOnceKey = "jailbreak_shown_once_key"
    private let debugLogKey = "debug_log_key"
    private let keyTransactionDataSortMode = "transaction_data_sort_mode"
    private let keyLockTimeEnabled = "lock_time_enabled"
    private let keyAppLaunchCount = "app_launch_count"
    private let keyRateAppLastRequestDate = "rate_app_last_request_date"
    private let keyBalanceHidden = "balance_hidden"
    private let keyDefaultMarketCategory = "default_market_category"
    private let keyZCashRewind = "z_cash_always_pending_rewind"
    private let keyDefaultProvider = "swap_provider"

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

    var agreementAccepted: Bool {
        get { storage.value(for: agreementAcceptedKey) ?? false }
        set { storage.set(value: newValue, for: agreementAcceptedKey) }
    }

    var sortType: SortType? {
        get {
            guard let sortRawValue: Int = storage.value(for: keySortType) else {
                return nil
            }
            return SortType(rawValue: sortRawValue)
        }
        set {
            storage.set(value: newValue?.rawValue, for: keySortType)
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

    var jailbreakShownOnce: Bool {
        get { storage.value(for: jailbreakShownOnceKey) ?? false }
        set { storage.set(value: newValue, for: jailbreakShownOnceKey) }
    }

    var transactionDataSortMode: TransactionDataSortMode? {
        get {
            if let rawValue: String = storage.value(for: keyTransactionDataSortMode), let value = TransactionDataSortMode(rawValue: rawValue) {
                return value
            }
            return nil
        }
        set {
            storage.set(value: newValue?.rawValue, for: keyTransactionDataSortMode)
        }
    }

    var lockTimeEnabled: Bool {
        get { storage.value(for: keyLockTimeEnabled) ?? false }
        set { storage.set(value: newValue, for: keyLockTimeEnabled) }
    }

    var appLaunchCount: Int {
        get { storage.value(for: keyAppLaunchCount) ?? 0 }
        set { storage.set(value: newValue, for: keyAppLaunchCount) }
    }

    var rateAppLastRequestDate: Date? {
        get { storage.value(for: keyRateAppLastRequestDate) }
        set { storage.set(value: newValue, for: keyRateAppLastRequestDate) }
    }

    var balanceHidden: Bool {
        get { storage.value(for: keyBalanceHidden) ?? false }
        set { storage.set(value: newValue, for: keyBalanceHidden) }
    }

    var marketCategory: Int? {
        get { storage.value(for: keyDefaultMarketCategory) }
        set { storage.set(value: newValue, for: keyDefaultMarketCategory) }
    }

    var zcashAlwaysPendingRewind: Bool {
        get { storage.value(for: keyZCashRewind) ?? false }
        set { storage.set(value: newValue, for: keyZCashRewind) }
    }

    func defaultProvider(blockchain: SwapModule.Dex.Blockchain) -> SwapModule.Dex.Provider {
        let key = [keyDefaultProvider, blockchain.rawValue, blockchain.isMainNet.description].joined(separator: "|")
        let raw: String? = storage.value(for: key)
        return (raw.flatMap { SwapModule.Dex.Provider(rawValue: $0) }) ?? blockchain.allowedProviders[0]
    }

    func setDefaultProvider(blockchain: SwapModule.Dex.Blockchain, provider: SwapModule.Dex.Provider) {
        let key = [keyDefaultProvider, blockchain.rawValue, blockchain.isMainNet.description].joined(separator: "|")
        storage.set(value: provider.rawValue, for: key)
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
