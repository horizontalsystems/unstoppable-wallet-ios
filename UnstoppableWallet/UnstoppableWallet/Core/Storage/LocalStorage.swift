import Foundation
import StorageKit
import MarketKit

class LocalStorage {
    private let agreementAcceptedKey = "i_understand_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let keySendInputType = "amount-type-switch-service-amount-type"
    private let keyChartInterval = "chart_type_key"
    private let mainShownOnceKey = "main_shown_once_key"
    private let jailbreakShownOnceKey = "jailbreak_shown_once_key"
    private let debugLogKey = "debug_log_key"
    private let keyLockTimeEnabled = "lock_time_enabled"
    private let keyAppLaunchCount = "app_launch_count"
    private let keyRateAppLastRequestDate = "rate_app_last_request_date"
    private let keyZCashRewind = "z_cash_always_pending_rewind"
    private let keyDefaultProvider = "swap_provider"

    private let storage: StorageKit.ILocalStorage

    init(storage: StorageKit.ILocalStorage) {
        self.storage = storage
    }

}

extension LocalStorage {

    var debugLog: String? {
        get { storage.value(for: debugLogKey) }
        set { storage.set(value: newValue, for: debugLogKey) }
    }

    var agreementAccepted: Bool {
        get { storage.value(for: agreementAcceptedKey) ?? false }
        set { storage.set(value: newValue, for: agreementAcceptedKey) }
    }

    var mainShownOnce: Bool {
        get { storage.value(for: mainShownOnceKey) ?? false }
        set { storage.set(value: newValue, for: mainShownOnceKey) }
    }

    var jailbreakShownOnce: Bool {
        get { storage.value(for: jailbreakShownOnceKey) ?? false }
        set { storage.set(value: newValue, for: jailbreakShownOnceKey) }
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

    var zcashAlwaysPendingRewind: Bool {
        get { storage.value(for: keyZCashRewind) ?? false }
        set { storage.set(value: newValue, for: keyZCashRewind) }
    }

    func defaultProvider(blockchainType: BlockchainType) -> SwapModule.Dex.Provider {
        let key = [keyDefaultProvider, blockchainType.uid].joined(separator: "|")
        let raw: String? = storage.value(for: key)
        return (raw.flatMap { SwapModule.Dex.Provider(rawValue: $0) }) ?? blockchainType.allowedProviders[0]
    }

    func setDefaultProvider(blockchainType: BlockchainType, provider: SwapModule.Dex.Provider) {
        let key = [keyDefaultProvider, blockchainType.uid].joined(separator: "|")
        storage.set(value: provider.rawValue, for: key)
    }

    var chartInterval: HsTimePeriod? {
        get {
            if let rawValue: String = storage.value(for: keyChartInterval), let interval = HsTimePeriod(rawValue: rawValue) {
                return interval
            }
            return nil
        }
        set {
            storage.set(value: newValue?.rawValue, for: keyChartInterval)
        }
    }

}
