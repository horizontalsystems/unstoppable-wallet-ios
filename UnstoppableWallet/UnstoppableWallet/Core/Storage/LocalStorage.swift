import Foundation
import MarketKit
import StorageKit

class LocalStorage {
    private let agreementAcceptedKey = "i_understand_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let keySendInputType = "amount-type-switch-service-amount-type"
    private let mainShownOnceKey = "main_shown_once_key"
    private let jailbreakShownOnceKey = "jailbreak_shown_once_key"
    private let debugLogKey = "debug_log_key"
    private let keyLockTimeEnabled = "lock_time_enabled"
    private let keyAppLaunchCount = "app_launch_count"
    private let keyRateAppLastRequestDate = "rate_app_last_request_date"
    private let keyZCashRewind = "z_cash_always_pending_rewind"
    private let keyDefaultProvider = "swap_provider"
    private let keyRemoteContactSync = "icloud-sync-value"
    private let keyUserChartIndicatorsSync = "user-chart-indicators"
    private let keyIndicatorsShown = "indicators-shown"
    private let keyTelegramSupportRequested = "telegram-support-requested"

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

    var remoteContactsSync: Bool {
        get { storage.value(for: keyRemoteContactSync) ?? false }
        set { storage.set(value: newValue, for: keyRemoteContactSync) }
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

    var chartIndicators: Data? {
        get { storage.value(for: keyUserChartIndicatorsSync) }
        set { storage.set(value: newValue, for: keyUserChartIndicatorsSync) }
    }

    var indicatorsShown: Bool {
        get { storage.value(for: keyIndicatorsShown) ?? true }
        set { storage.set(value: newValue, for: keyIndicatorsShown) }
    }

    var telegramSupportRequested: Bool {
        get { storage.value(for: keyTelegramSupportRequested) ?? false }
        set { storage.set(value: newValue, for: keyTelegramSupportRequested) }
    }
}

extension LocalStorage {
    var backup: [String: Any] {
        var fields: [String: Any] = [
            "lock_time_enabled": lockTimeEnabled.description,
            "contacts_sync": remoteContactsSync.description,
            "show_indicators": indicatorsShown.description,
        ]

        if let chartIndicators {
            fields["chart_indicators"] = chartIndicators.hs.hexString
        }

        let providers: [String: String] = BlockchainType
            .supported
            .filter { !$0.allowedProviders.isEmpty }
            .map { ($0.uid, defaultProvider(blockchainType: $0).rawValue) }
            .reduce(into: [:]) { $0[$1.0] = $1.1 }

        fields["swap_providers"] = providers

        return fields
    }

    private func bool(value: Any?) -> Bool? {
        if let string = value as? String,
           let enabled = Bool(string) {
            return enabled
        }
        return nil
    }

    func restore(backup _: [String: Any]) {
        if let lockTime = bool(value: backup["lock_time_enabled"]) {
            lockTimeEnabled = lockTime
        }
        if let contactsSync = bool(value: backup["contacts_sync"]) {
            remoteContactsSync = contactsSync
        }
        if let showIndicators = bool(value: backup["show_indicators"]) {
            indicatorsShown = showIndicators
        }

        if let chartIndicators = backup["chart_indicators"] as? String,
           let data = chartIndicators.hs.hexData {
            self.chartIndicators = data
        }

        if let providers = backup["swap_providers"] as? [String: String] {
            providers.forEach { key, value in
                let type = BlockchainType(uid: key)
                if let provider = SwapModule.Dex.Provider(rawValue: value),
                   !type.allowedProviders.isEmpty {

                    setDefaultProvider(blockchainType: type, provider: provider)
                }
            }
        }
    }
}
