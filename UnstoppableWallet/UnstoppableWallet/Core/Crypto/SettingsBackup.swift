import Foundation
import Chart
import CurrencyKit
import ThemeKit

struct SettingsBackup: Codable {
    let evmSyncSources: EvmSyncSourceManager.SyncSourceBackup

    let lockTimeEnabled: Bool
    let remoteContactsSync: Bool
    let defaultProviders: [DefaultProvider]
    let chartIndicators: [ChartIndicator]
    let indicatorsShown: Bool
    let currentLanguage: String
    let baseCurrency: String

    let mode: ThemeMode
    let showMarketTab: Bool
    let launchScreen: LaunchScreen
    let conversionTokenQueryId: String?
    let balancePrimaryValue: BalancePrimaryValue
    let balanceAutoHide: Bool
    let appIcon: String

    enum CodingKeys: String, CodingKey {
        case evmSyncSources = "evm_sync_sources"
        case lockTimeEnabled = "lock_time"
        case remoteContactsSync = "contacts_sync"
        case defaultProviders = "default_providers"
        case chartIndicators = "indicators"
        case indicatorsShown = "indicators_shown"
        case currentLanguage = "language"
        case baseCurrency = "currency"
        case mode = "theme_mode"
        case showMarketTab = "show_market"
        case launchScreen = "launch_screen"
        case conversionTokenQueryId = "conversion_token_query_id"
        case balancePrimaryValue = "balance_primary_value"
        case balanceAutoHide = "balance_auto_hide"
        case appIcon = "app_icon"
    }

}

extension SettingsBackup {
    struct DefaultProvider: Codable {
        enum CodingKeys: String, CodingKey {
            case blockchainTypeId = "blockchain_type_id"
            case provider
        }

        let blockchainTypeId: String
        let provider: String
    }
}