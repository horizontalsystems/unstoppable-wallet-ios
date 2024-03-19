import Foundation
import MarketKit

class LocalStorage {
    private let agreementAcceptedKey = "i_understand_key"
    private let biometricOnKey = "biometric_on_key"
    private let lastExitDateKey = "last_exit_date_key"
    private let keySendInputType = "amount-type-switch-service-amount-type"
    private let mainShownOnceKey = "main_shown_once_key"
    private let jailbreakShownOnceKey = "jailbreak_shown_once_key"
    private let debugLogKey = "debug_log_key"
    private let keyAppLaunchCount = "app_launch_count"
    private let keyRateAppLastRequestDate = "rate_app_last_request_date"
    private let keyZCashRewind = "z_cash_always_pending_rewind"
    private let keyDefaultProvider = "swap_provider"
    private let keyRemoteContactSync = "icloud-sync-value"
    private let keyUserChartIndicatorsSync = "user-chart-indicators"
    private let keyIndicatorsShown = "indicators-shown"
    private let keyTelegramSupportRequested = "telegram-support-requested"

    private let userDefaultsStorage: UserDefaultsStorage

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage
    }
}

extension LocalStorage {
    var debugLog: String? {
        get { userDefaultsStorage.value(for: debugLogKey) }
        set { userDefaultsStorage.set(value: newValue, for: debugLogKey) }
    }

    var agreementAccepted: Bool {
        get { userDefaultsStorage.value(for: agreementAcceptedKey) ?? false }
        set { userDefaultsStorage.set(value: newValue, for: agreementAcceptedKey) }
    }

    var mainShownOnce: Bool {
        get { userDefaultsStorage.value(for: mainShownOnceKey) ?? false }
        set { userDefaultsStorage.set(value: newValue, for: mainShownOnceKey) }
    }

    var jailbreakShownOnce: Bool {
        get { userDefaultsStorage.value(for: jailbreakShownOnceKey) ?? false }
        set { userDefaultsStorage.set(value: newValue, for: jailbreakShownOnceKey) }
    }

    var remoteContactsSync: Bool {
        get { userDefaultsStorage.value(for: keyRemoteContactSync) ?? false }
        set { userDefaultsStorage.set(value: newValue, for: keyRemoteContactSync) }
    }

    var appLaunchCount: Int {
        get { userDefaultsStorage.value(for: keyAppLaunchCount) ?? 0 }
        set { userDefaultsStorage.set(value: newValue, for: keyAppLaunchCount) }
    }

    var rateAppLastRequestDate: Date? {
        get { userDefaultsStorage.value(for: keyRateAppLastRequestDate) }
        set { userDefaultsStorage.set(value: newValue, for: keyRateAppLastRequestDate) }
    }

    var zcashAlwaysPendingRewind: Bool {
        get { userDefaultsStorage.value(for: keyZCashRewind) ?? false }
        set { userDefaultsStorage.set(value: newValue, for: keyZCashRewind) }
    }

    func defaultProvider(blockchainType: BlockchainType) -> SwapModule.Dex.Provider {
        let key = [keyDefaultProvider, blockchainType.uid].joined(separator: "|")
        let raw: String? = userDefaultsStorage.value(for: key)
        return (raw.flatMap { SwapModule.Dex.Provider(rawValue: $0) }) ?? blockchainType.allowedProviders[0]
    }

    func setDefaultProvider(blockchainType: BlockchainType, provider: SwapModule.Dex.Provider) {
        let key = [keyDefaultProvider, blockchainType.uid].joined(separator: "|")
        userDefaultsStorage.set(value: provider.rawValue, for: key)
    }

    var chartIndicators: Data? {
        get { userDefaultsStorage.value(for: keyUserChartIndicatorsSync) }
        set { userDefaultsStorage.set(value: newValue, for: keyUserChartIndicatorsSync) }
    }

    var indicatorsShown: Bool {
        get { userDefaultsStorage.value(for: keyIndicatorsShown) ?? true }
        set { userDefaultsStorage.set(value: newValue, for: keyIndicatorsShown) }
    }

    var telegramSupportRequested: Bool {
        get { userDefaultsStorage.value(for: keyTelegramSupportRequested) ?? false }
        set { userDefaultsStorage.set(value: newValue, for: keyTelegramSupportRequested) }
    }
}

extension LocalStorage {
    func restore(backup: SettingsBackup) {
        remoteContactsSync = backup.remoteContactsSync ?? false
        indicatorsShown = backup.indicatorsShown
        backup.swapProviders.forEach { provider in
            let blockchainType = BlockchainType(uid: provider.blockchainTypeId)
            if let dexProvider = SwapModule.Dex.Provider(rawValue: provider.provider) {
                return setDefaultProvider(blockchainType: blockchainType, provider: dexProvider)
            }
        }
    }
}
